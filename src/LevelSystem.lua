-- LevelSystem handles progression between stages of the game. It is kept
-- extremely small for now but is expected to manage additional state such as
-- monster scaling in the future.

local LevelSystem = {}

--- Tracks the player's current level.
--  Starts at ``1`` when the game begins.
LevelSystem.currentLevel = 1

--- Advances the game to the next level and returns the new level value.
--  The explicit increment keeps compatibility with Lua 5.1.
--  @return number The current level after the increment
function LevelSystem:advance()
    self.currentLevel = self.currentLevel + 1
    -- TODO: spawn stronger monsters
    return self.currentLevel
end

return LevelSystem
