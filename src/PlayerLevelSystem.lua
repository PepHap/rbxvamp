-- PlayerLevelSystem.lua
-- Manages player experience, levels and content unlocks.

local PlayerLevelSystem = {}

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
    end
end

---Adds experience to the player and processes level ups.
-- @param amount number non-negative experience amount to add
function PlayerLevelSystem:addExperience(amount)
    assert(type(amount) == "number" and amount >= 0, "amount must be non-negative")
    self.exp = self.exp + amount
    self:checkThreshold()
end

return PlayerLevelSystem
