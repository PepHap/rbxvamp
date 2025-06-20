-- PlayerLevelSystem.lua
-- Manages player experience, levels and content unlocks.

local PlayerLevelSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))

---Current player level starting at ``1``.
PlayerLevelSystem.level = 1

---Current accumulated experience.
PlayerLevelSystem.exp = 0

---Experience required to reach the next level.
PlayerLevelSystem.nextExp = 100

---List of content identifiers unlocked so far.
PlayerLevelSystem.unlocked = {}

-- Milestone table mapping levels to content keys that unlock at that level.
local milestones = {
    [5] = "skills",
    [10] = "companions",
    [20] = "new_area"
}

---Unlocks content when a milestone level is reached.
-- @param lvl number level that was reached
function PlayerLevelSystem:unlockForLevel(lvl)
    local content = milestones[lvl]
    if content then
        table.insert(self.unlocked, content)
    end
end

---Checks if enough experience was gained to advance the player's level.
function PlayerLevelSystem:checkThreshold()
    while self.exp >= self.nextExp do
        self.exp = self.exp - self.nextExp
        self.level = self.level + 1
        -- Increase required experience slightly each level
        self.nextExp = math.floor(self.nextExp * 1.2)
        self:unlockForLevel(self.level)
        -- notify listeners of the level up
        local ev = EventManager:Get("PlayerLevelUp")
        ev:Fire(self.level)
    end
end

---Adds experience to the player and processes level ups.
-- @param amount number non-negative experience amount to add
function PlayerLevelSystem:addExperience(amount)
    assert(type(amount) == "number" and amount >= 0, "amount must be non-negative")
    self.exp = self.exp + amount
    self:checkThreshold()
end

---Serializes the current player level data for persistence.
-- @return table plain table with level, exp and unlocks
function PlayerLevelSystem:saveData()
    return {
        level = self.level,
        exp = self.exp,
        nextExp = self.nextExp,
        unlocked = self.unlocked,
    }
end

---Loads level data previously produced by ``saveData``.
-- Unknown fields are ignored.
-- @param data table data table
function PlayerLevelSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.level) == "number" then
        self.level = data.level
    end
    if type(data.exp) == "number" then
        self.exp = data.exp
    end
    if type(data.nextExp) == "number" then
        self.nextExp = data.nextExp
    end
    if type(data.unlocked) == "table" then
        self.unlocked = {}
        for i, v in ipairs(data.unlocked) do
            self.unlocked[i] = v
        end
    end
end

return PlayerLevelSystem
