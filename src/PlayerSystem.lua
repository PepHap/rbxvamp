-- PlayerSystem.lua
-- Tracks player health and handles death events.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local PlayerSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))

-- Forward declarations for functions defined later in this file
local getSpawnPosition
local spawnModel

---Indicates if a Roblox model should be created for the player when the game
--  starts. Tests can disable this to avoid manipulating Instance objects.
PlayerSystem.spawnModels = true

---When enabled and running inside Roblox, real Instances will be created
--  rather than simple Lua tables.
PlayerSystem.useRobloxObjects = EnvironmentUtil.detectRoblox()

---Current player position in the world.
PlayerSystem.position = {x = 0, y = 0, z = 0}

---Reference to the player's model table or Instance.
PlayerSystem.model = nil

local LevelSystem -- lazy loaded to avoid circular dependency
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local AntiCheatSystem = require(script.Parent:WaitForChild("AntiCheatSystem"))

-- Forward declare helper functions so they can be referenced inside
-- PlayerSystem methods defined above them.
local createVector3
local getSpawnPosition
local spawnModel
local function broadcastState()
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("PlayerState", PlayerSystem.health, PlayerSystem.position)
    end
end

---Maximum player health.
PlayerSystem.maxHealth = 100

---Current player health.
PlayerSystem.health = PlayerSystem.maxHealth

---Damages the player by the given amount and checks for death.
-- @param amount number amount of damage to apply
function PlayerSystem:takeDamage(amount)
    local n = tonumber(amount) or 0
    self.health = self.health - n
    if self.health <= 0 then
        self.health = 0
        self:onDeath()
    end
    EventManager:Get("PlayerDamaged"):Fire(amount, self.health)
    broadcastState()
end

---Heals the player by the given amount without exceeding max health.
-- @param amount number amount to heal
function PlayerSystem:heal(amount)
    local n = tonumber(amount) or 0
    self.health = math.min(self.health + n, self.maxHealth)
    EventManager:Get("PlayerHealed"):Fire(amount, self.health)
    broadcastState()
end

---Handles player death and notifies the LevelSystem.
function PlayerSystem:onDeath()
    -- load LevelSystem here to avoid circular require error
    if not LevelSystem then
        LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
    end
    if LevelSystem and LevelSystem.onPlayerDeath then
        LevelSystem:onPlayerDeath()
    end
    self.health = self.maxHealth
    local spawnPos = getSpawnPosition()
    self:setPosition(spawnPos)
    if not self.model then
        spawnModel()
    end
    EventManager:Get("PlayerDied"):Fire()
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("PlayerDied")
    end
    broadcastState()
end

---Utility converting coordinates into ``Vector3`` values when running inside
--  Roblox. Falls back to simple tables in a test environment.
function createVector3(x, y, z)
    local ok, ctor = pcall(function()
        return Vector3.new
    end)
    if ok and type(ctor) == "function" then
        return ctor(x, y, z)
    end
    return {x = x, y = y, z = z}
end

function getSpawnPosition()
    local loc = LocationSystem and LocationSystem.getCurrent and LocationSystem:getCurrent()
    if loc and loc.coordinates then
        return {x = loc.coordinates.x, y = loc.coordinates.y, z = loc.coordinates.z}
    end
    return {x = 0, y = 0, z = 0}
end

---Spawns a very simple Roblox model for the player or a table representation
--  during tests. The model/instance is stored in ``PlayerSystem.model``.
function spawnModel()
    if PlayerSystem.spawnModels == false then
        return nil
    end

    if PlayerSystem.useRobloxObjects and game ~= nil then
        local ok, players = pcall(function()
            return game:GetService("Players")
        end)
        if ok and players then
            local localPlayer
            local runService = game:GetService("RunService")
            if runService:IsClient() then
                localPlayer = players.LocalPlayer
            else
                localPlayer = players:GetPlayers()[1]
            end
            if localPlayer then
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                PlayerSystem.model = character
                local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                if hrp then
                    local pos = hrp.Position
                    PlayerSystem.position = {x = pos.X, y = pos.Y, z = pos.Z}
                end
                return character
            end
        end
    end

    -- Fallback table model used outside Roblox
    local model = {
        primaryPart = {
            position = {
                x = PlayerSystem.position.x,
                y = PlayerSystem.position.y,
                z = PlayerSystem.position.z
            }
        }
    }
    model.billboardGui = {
        adornee = model.primaryPart,
        textLabel = {text = "Player"}
    }
    PlayerSystem.model = model
    return model
end

function PlayerSystem:setPosition(pos)
    pos = pos or {x = 0, y = 0, z = 0}
    if self.position then
        self.position.x = pos.x
        self.position.y = pos.y
        self.position.z = pos.z
    else
        self.position = {x = pos.x, y = pos.y, z = pos.z}
    end
    AutoBattleSystem.playerPosition = self.position
    AntiCheatSystem:checkMovement(nil, self.position)
    local model = self.model
    if model then
        local part = model.PrimaryPart or model.primaryPart
        if part then
            if part.Position ~= nil then
                part.Position = createVector3(pos.x, pos.y, pos.z)
            else
                part.position = {x = pos.x, y = pos.y, z = pos.z}
            end
        end
    end
    broadcastState()
end

---Initializes the player state and spawns a model when the game starts.
function PlayerSystem:start()
    self.health = self.maxHealth
    local pos = getSpawnPosition()
    self.position = {x = pos.x, y = pos.y, z = pos.z}
    AutoBattleSystem.playerPosition = self.position
    if self.spawnModels ~= false then
        spawnModel()
    end
    broadcastState()
end

---Updates the cached player position from the Roblox character when available.
-- @param dt number delta time (unused)
function PlayerSystem:update(dt)
    if not self.useRobloxObjects then
        return
    end
    local model = self.model
    if model and model.Parent then
        local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if hrp and hrp.Position then
            local pos = hrp.Position
            self.position.x = pos.X
            self.position.y = pos.Y
            self.position.z = pos.Z
            AutoBattleSystem.playerPosition = self.position
            AntiCheatSystem:checkMovement(nil, self.position)
            broadcastState()
        end
    end
end

return PlayerSystem
