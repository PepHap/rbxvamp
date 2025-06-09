-- LevelSystem handles progression between stages of the game. It is kept
-- extremely small for now but is expected to manage additional state such as
-- monster scaling in the future.

local LevelSystem = {}

-- Enemy system is required so that level progression can trigger new waves
-- or boss spawns depending on the current level reached.
local EnemySystem = require("src.EnemySystem")

--- Tracks the player's current level.
--  Starts at ``1`` when the game begins.
LevelSystem.currentLevel = 1

--- Number of monsters killed on the current level.
LevelSystem.killCount = 0

--- Number of kills required to advance to the next level.
LevelSystem.requiredKills = 15

--- Internal helper that increases monster stats. Placeholder for future
--  implementation where monsters gain more health or damage each level.
function LevelSystem:strengthenMonsters()
    -- TODO: implement monster stat scaling
end

--- Checks if the player has enough kills to advance and, if so,
--  progresses to the next level.
function LevelSystem:checkAdvance()
    if self.killCount >= self.requiredKills then
        self.killCount = self.killCount - self.requiredKills
        self:advance()
    end
end

--- Increments the kill counter and automatically checks for advancement.
function LevelSystem:addKill()
    self.killCount = self.killCount + 1
    self:checkAdvance()
end

--- Advances the game to the next level and returns the new level value.
--  The explicit increment keeps compatibility with Lua 5.1.
--  @return number The current level after the increment
function LevelSystem:advance()
    self.currentLevel = self.currentLevel + 1
    self.killCount = 0
    self.requiredKills = self.requiredKills + 5
    self:strengthenMonsters()
    -- Determine what kind of enemy encounter should occur on this level.
    -- Every 30th level spawns a strong location boss, every 10th level a boss,
    -- and every 5th level a mini-boss. All other levels spawn a normal wave.
    if self.currentLevel % 30 == 0 then
        EnemySystem:spawnBoss("location")
    elseif self.currentLevel % 10 == 0 then
        EnemySystem:spawnBoss("boss")
    elseif self.currentLevel % 5 == 0 then
        EnemySystem:spawnBoss("mini")
    else
        EnemySystem:spawnWave(self.currentLevel)
    end
    return self.currentLevel
end

return LevelSystem
