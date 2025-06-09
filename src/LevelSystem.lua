-- LevelSystem.lua
-- Handles progression through levels and scaling monsters

local LevelSystem = {}
LevelSystem.__index = LevelSystem

---Creates a new level system starting at level 1.
-- @return table
function LevelSystem.new()
    return setmetatable({currentLevel = 1}, LevelSystem)
end

function LevelSystem:getLevel()
    return self.currentLevel
end

function LevelSystem:advance()
    self.currentLevel = self.currentLevel + 1
    -- TODO: spawn stronger monsters
end

return LevelSystem
