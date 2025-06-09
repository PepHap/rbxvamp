-- LevelSystem.lua
-- Handles progression through levels and scaling monsters

local LevelSystem = {}

-- Tracks the player's current level
LevelSystem.currentLevel = 1

---Advances the game to the next level.
-- Explicitly increments to remain Lua 5.1 compatible.
function LevelSystem:advance()
    self.currentLevel = self.currentLevel + 1
    -- TODO: spawn stronger monsters
end

-- Backwards compatibility alias
LevelSystem.nextLevel = LevelSystem.advance

return LevelSystem
