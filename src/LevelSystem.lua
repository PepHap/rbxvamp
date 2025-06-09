-- LevelSystem.lua
-- Handles progression through levels and scaling monsters

local LevelSystem = {}

LevelSystem.currentLevel = 1

function LevelSystem:advance()
    self.currentLevel = self.currentLevel + 1
    -- TODO: spawn stronger monsters
end

return LevelSystem
