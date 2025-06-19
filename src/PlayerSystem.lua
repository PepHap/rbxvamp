-- PlayerSystem.lua
-- Tracks player health and handles death events.

local PlayerSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))

---Indicates if a Roblox model should be created for the player when the game
--  starts. Tests can disable this to avoid manipulating Instance objects.
PlayerSystem.spawnModels = true

---When enabled and running inside Roblox, real Instances will be created
--  rather than simple Lua tables.
PlayerSystem.useRobloxObjects = false

---Current player position in the world.
PlayerSystem.position = {x = 0, y = 0, z = 0}

---Reference to the player's model table or Instance.
PlayerSystem.model = nil

local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))

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
end

---Heals the player by the given amount without exceeding max health.
-- @param amount number amount to heal
function PlayerSystem:heal(amount)
    local n = tonumber(amount) or 0
    self.health = math.min(self.health + n, self.maxHealth)
    EventManager:Get("PlayerHealed"):Fire(amount, self.health)
end

---Handles player death and notifies the LevelSystem.
function PlayerSystem:onDeath()
    LevelSystem:onPlayerDeath()
    self.health = self.maxHealth
    EventManager:Get("PlayerDied"):Fire()
end

---Utility converting coordinates into ``Vector3`` values when running inside
--  Roblox. Falls back to simple tables in a test environment.
local function createVector3(x, y, z)
    local ok, ctor = pcall(function()
        return Vector3.new
    end)
    if ok and type(ctor) == "function" then
        return ctor(x, y, z)
    end
    return {x = x, y = y, z = z}
end

local function getSpawnPosition()
    local loc = LocationSystem and LocationSystem.getCurrent and LocationSystem:getCurrent()
    if loc and loc.coordinates then
        return {x = loc.coordinates.x, y = loc.coordinates.y, z = loc.coordinates.z}
    end
    return {x = 0, y = 0, z = 0}
end

---Spawns a very simple Roblox model for the player or a table representation
--  during tests. The model/instance is stored in ``PlayerSystem.model``.
local function spawnModel()
    if PlayerSystem.spawnModels == false then
        return nil
    end

    if PlayerSystem.useRobloxObjects and typeof ~= nil and Instance ~= nil and game ~= nil then
        local ok, workspaceService = pcall(function()
            return game:GetService("Workspace")
        end)
        if ok and workspaceService then
            local model = Instance.new("Model")
            model.Name = "Player"

            local part = Instance.new("Part")
            part.Name = "PlayerPart"
            part.Position = createVector3(PlayerSystem.position.x, PlayerSystem.position.y, PlayerSystem.position.z)
            part.Parent = model
            model.PrimaryPart = part

            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Adornee = part
            local textLabel = Instance.new("TextLabel")
            textLabel.Text = "Player"
            textLabel.Parent = billboardGui
            billboardGui.Parent = model

            model.Parent = workspaceService
            PlayerSystem.model = model
            return model
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
end

return PlayerSystem
