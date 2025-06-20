-- LevelSystem handles progression between stages of the game. It is kept
-- extremely small for now but is expected to manage additional state such as
-- monster scaling in the future.

local LevelSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))

--- Highest stage the player has cleared so far.
LevelSystem.highestClearedStage = 0

-- Enemy system is required so that level progression can trigger new waves
-- or boss spawns depending on the current level reached.
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local WaveConfig = require(script.Parent:WaitForChild("WaveConfig"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local PlayerSystem -- loaded on demand to avoid circular dependency

--- Tracks the player's current level.
--  Starts at ``1`` when the game begins.
LevelSystem.currentLevel = 1

--- Number of monsters killed on the current level.
LevelSystem.killCount = 0

--- Number of kills required to advance to the next level.
LevelSystem.requiredKills = 15

---Number of enemies spawned per wave.
LevelSystem.waveSize = 5

---Resets stage tracking and spawns the initial enemy wave.
--  This is called when the overall game begins via ``GameManager``.
function LevelSystem:start()
    self.currentLevel = 1
    self.killCount = 0
    self.requiredKills = 15
    local cfg = WaveConfig.levels[1]
    if cfg and not cfg.boss then
        EnemySystem:spawnWaveForLevel(1, cfg)
    else
        EnemySystem:spawnWave(1, self.waveSize)
    end
    EventManager:Get("LevelStart"):Fire(1)
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

---Ensures a new wave is spawned whenever all enemies are defeated.
--  This keeps gameplay flowing on early floors where only a few foes spawn.
--  Called every frame by ``GameManager``.
function LevelSystem:update()
    -- Do nothing if the player already cleared this stage
    if self.killCount >= self.requiredKills then
        return
    end
    -- Spawn another wave when no enemies remain
    if #EnemySystem.enemies == 0 then
        local remaining = self.requiredKills - self.killCount
        local count = math.min(self.waveSize, remaining)
        local cfg = WaveConfig.levels[self.currentLevel]
        if cfg and not cfg.boss then
            EnemySystem:spawnWaveForLevel(self.currentLevel, cfg)
        else
            EnemySystem:spawnWave(self.currentLevel, count)
        end
    end
end

--- Advances the game to the next level and returns the new level value.
--  The explicit increment keeps compatibility with Lua 5.1.
--  @return number The current level after the increment
function LevelSystem:advance()
    -- load PlayerSystem lazily to avoid circular require issues
    if not PlayerSystem then
        PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
    end
    local nextLevel = self.currentLevel + 1
    local stageType = getStageType(nextLevel)

    if stageType == "location" then
        -- Player must have unlocked access to new areas
        if not (PlayerLevelSystem and PlayerLevelSystem.isUnlocked and PlayerLevelSystem:isUnlocked("new_area")) then
            return nil
        end
        -- Require a location key to move to the next area
        if not KeySystem:useKey("location") then
            return nil
        end
        LocationSystem:advance()
        local loc = LocationSystem:getCurrent()
        if loc and loc.coordinates and PlayerSystem and PlayerSystem.setPosition then
            PlayerSystem:setPosition(loc.coordinates)
        end
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
        local cfg = WaveConfig.levels[self.currentLevel]
        if cfg and not cfg.boss then
            EnemySystem:spawnWaveForLevel(self.currentLevel, cfg)
        else
            EnemySystem:spawnWave(self.currentLevel, self.waveSize)
        end
    end
    EventManager:Get("LevelAdvance"):Fire(self.currentLevel, stageType)
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
    EventManager:Get("PlayerDeath"):Fire(lvl)
end

return LevelSystem
