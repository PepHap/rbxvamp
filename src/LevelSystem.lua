-- LevelSystem.lua
-- Handles progression through levels and scaling monsters

local LevelSystem = {}

-- Tracks the player's current level
LevelSystem.currentLevel = 1

---
-- Advances the game to the next level.
-- Uses explicit addition to remain Lua 5.1 compatible.
function LevelSystem:nextLevel()
    -- Lua 5.1 lacks the '+=' operator, so we update manually
    self.currentLevel = self.currentLevel + 1
    -- TODO: spawn stronger monsters
end

return LevelSystem
