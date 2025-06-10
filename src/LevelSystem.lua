-- LevelSystem handles progression between stages of the game. It is kept
-- extremely small for now but is expected to manage additional state such as
-- monster scaling in the future.

local LevelSystem = {}

--- Highest stage the player has cleared so far.
LevelSystem.highestClearedStage = 0

-- Enemy system is required so that level progression can trigger new waves
-- or boss spawns depending on the current level reached.
local EnemySystem = require("src.EnemySystem")
local KeySystem = require("src.KeySystem")
local LocationSystem = require("src.LocationSystem")

--- Tracks the player's current level.
--  Starts at ``1`` when the game begins.
LevelSystem.currentLevel = 1

--- Number of monsters killed on the current level.
LevelSystem.killCount = 0

--- Number of kills required to advance to the next level.
LevelSystem.requiredKills = 15

---Resets stage tracking and spawns the initial enemy wave.
--  This is called when the overall game begins via ``GameManager``.
function LevelSystem:start()
    self.currentLevel = 1
    self.killCount = 0
    self.requiredKills = 15
    EnemySystem:spawnWave(1)
end

---Determines the type of a given stage.
-- @param level number stage number
-- @return string one of "normal", "mini", "boss", "location"
local function getStageType(level)
    if level % 30 == 0 then
        return "location"
    elseif level % 10 == 0 then
        return "boss"
    elseif level % 5 == 0 then
        return "mini"
    else
        return "normal"
    end
end
--- Internal helper that increases monster stats based on the stage type.
-- @param stageType string type returned by ``getStageType``
function LevelSystem:strengthenMonsters(stageType)
    local factors = {
        normal = 1.05,
        mini = 1.1,
        boss = 1.15,
        location = 1.25
    }
    local factor = factors[stageType] or 1.05
    EnemySystem.healthScale = (EnemySystem.healthScale or 1) * factor
    EnemySystem.damageScale = (EnemySystem.damageScale or 1) * factor
end

--- Checks if the player has enough kills to advance and, if so,
--  progresses to the next level.
function LevelSystem:checkAdvance()
    if self.killCount >= self.requiredKills then
        self.killCount = self.killCount - self.requiredKills
        local ok = self:advance()
        if not ok then
            -- Revert kill deduction if advancement was blocked
            self.killCount = self.killCount + self.requiredKills
        end
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
    local nextLevel = self.currentLevel + 1
    local stageType = getStageType(nextLevel)

    if stageType == "location" then
        -- Require a location key to move to the next area
        if not KeySystem:useKey("location") then
            return nil
        end
        LocationSystem:advance()
    end

    self.currentLevel = nextLevel
    self.killCount = 0
    self.requiredKills = self.requiredKills + 5

    -- Record the highest stage cleared which is the previous level.
    if self.currentLevel - 1 > self.highestClearedStage then
        self.highestClearedStage = self.currentLevel - 1
    end

    self:strengthenMonsters(stageType)

    -- Determine what kind of enemy encounter should occur on this level.
    if stageType == "location" then
        EnemySystem:spawnBoss("location")
    elseif stageType == "boss" then
        EnemySystem:spawnBoss("boss")
    elseif stageType == "mini" then
        EnemySystem:spawnBoss("mini")
    else
        EnemySystem:spawnWave(self.currentLevel)
    end
    return self.currentLevel
end

---Handles player death and rolls back when dying to a mini-boss.
function LevelSystem:onPlayerDeath()
    local lvl = self.currentLevel
    -- Roll back only on mini-boss stages which occur every 5th level
    -- except when it is also a boss or strong boss stage.
    if lvl % 5 == 0 and lvl % 10 ~= 0 then
        self.currentLevel = math.max(lvl - 1, 1)
        self.killCount = 0
        self.requiredKills = self.requiredKills - 5
    end
end

return LevelSystem
