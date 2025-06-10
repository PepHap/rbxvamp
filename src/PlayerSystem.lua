-- PlayerSystem.lua
-- Tracks player health and handles death events.

local PlayerSystem = {}

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

local LevelSystem = require("src.LevelSystem")
local AutoBattleSystem = require("src.AutoBattleSystem")

---Maximum player health.
PlayerSystem.maxHealth = 100

---Current player health.
PlayerSystem.health = PlayerSystem.maxHealth

---Damages the player by the given amount and checks for death.
-- @param amount number amount of damage to apply
function PlayerSystem:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self:onDeath()
    end
end

---Heals the player by the given amount without exceeding max health.
-- @param amount number amount to heal
function PlayerSystem:heal(amount)
    self.health = math.min(self.health + amount, self.maxHealth)
end

---Handles player death and notifies the LevelSystem.
function PlayerSystem:onDeath()
    LevelSystem:onPlayerDeath()
    self.health = self.maxHealth
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

---Spawns a very simple Roblox model for the player or a table representation
--  during tests. The model/instance is stored in ``PlayerSystem.model``.
local function spawnModel()
    if PlayerSystem.spawnModels == false then
        return nil
    end

    if PlayerSystem.useRobloxObjects and Instance ~= nil and type(Instance.new) == "function" and game ~= nil then
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

---Initializes the player state and spawns a model when the game starts.
function PlayerSystem:start()
    self.health = self.maxHealth
    self.position = {x = 0, y = 0, z = 0}
    AutoBattleSystem.playerPosition = self.position
    if self.spawnModels ~= false then
        spawnModel()
    end
end

return PlayerSystem
