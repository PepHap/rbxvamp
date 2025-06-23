-- LevelSystem handles progression between stages of the game. It is kept
-- extremely small for now but is expected to manage additional state such as
-- monster scaling in the future.

local LevelSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local RunService = game:GetService("RunService")

--- Highest stage the player has cleared so far.
LevelSystem.highestClearedStage = 0

-- Enemy system is required so that level progression can trigger new waves
-- or boss spawns depending on the current level reached.
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local TeleportSystem = require(script.Parent:WaitForChild("TeleportSystem"))
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

---Returns how many kills are required to clear ``level``.
--  The amount scales gradually based on the current location
--  and every tenth floor becomes slightly harder.
--  @param level number target level
--  @return number kill requirement
function LevelSystem:getKillRequirement(level)
    level = level or self.currentLevel or 1
    local base = 15
    -- Increase requirement by 5 each new location (every 30 floors)
    local locIncrease = math.floor((level - 1) / 30) * 5
    -- Within a location bump the count slightly every 10 floors
    local segmentIncrease = math.floor(((level - 1) % 30) / 10) * 2
    return base + locIncrease + segmentIncrease
end

---Adjusts enemy stat multipliers based on the floor number.
--  Increases health and damage by 5% per level as a baseline.
--  @param level number stage level used for scaling
function LevelSystem:scaleStats(level)
    level = level or self.currentLevel or 1
    local factor = 1 + (level - 1) * 0.05
    -- bosses and mini bosses receive additional scaling
    if level % 10 == 0 then
        factor = factor * 1.2
    elseif level % 5 == 0 then
        factor = factor * 1.1
    end
    EnemySystem.healthScale = factor
    EnemySystem.damageScale = factor
end

---Number of enemies spawned per wave.
LevelSystem.baseWaveSize = 5
LevelSystem.waveSize = LevelSystem.baseWaveSize

local function updateWaveSize()
    LevelSystem.waveSize = LevelSystem.baseWaveSize + math.floor((LevelSystem.currentLevel - 1) / 3)
end

-- Broadcasts stage progress to all connected clients. This must only
-- be invoked from the server, otherwise ``RemoteEvent:FireAllClients``
-- will throw an error as documented in the Roblox reference:
-- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent#FireAllClients
local function broadcastProgress()
    if RunService:IsServer() and NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients(
            "LevelProgress",
            LevelSystem.currentLevel,
            LevelSystem.killCount,
            LevelSystem.requiredKills
        )
    end
end

---Returns level progress toward the next stage as a value from ``0`` to ``1``.
function LevelSystem:getPercent()
    if self.requiredKills <= 0 then
        return 0
    end
    return self.killCount / self.requiredKills
end

---Returns information about the upcoming stage.
--  @return number nextLevel
--  @return string stageType
--  @return number killsLeft
--  @return string|nil bossName
function LevelSystem:getNextStageInfo()
    local nextLevel = self.currentLevel + 1
    local killsLeft = math.max(0, (self.requiredKills or 0) - (self.killCount or 0))
    -- Use the exported method to avoid nil upvalues on partial loads
    local stageType = self.getStageType(nextLevel)
    local milestoneKills, _, milestoneType = self:getKillsUntilMilestone(self.currentLevel)
    local loc = LocationSystem:getCurrent()
    local bossName
    if loc and loc.bosses then
        bossName = loc.bosses[nextLevel]
    end
    return nextLevel, stageType, killsLeft, bossName, milestoneKills, milestoneType
end

---Resets stage tracking and spawns the initial enemy wave.
--  This is called when the overall game begins via ``GameManager``.
function LevelSystem:start()
    self.currentLevel = 1
    self.killCount = 0
    self.requiredKills = self:getKillRequirement(1)
    self:scaleStats(1)
    updateWaveSize()
    local cfg = WaveConfig.levels[1]
    if RunService:IsServer() then
        if cfg and not cfg.boss then
            EnemySystem:spawnWaveForLevel(1, cfg)
        else
            EnemySystem:spawnWave(1, self.waveSize)
        end
    end
    EventManager:Get("LevelStart"):Fire(1)
    broadcastProgress()
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

-- Expose stage classification so other systems like the scoreboard
-- or dungeon logic can easily query the current stage type.
function LevelSystem.getStageType(level)
    return getStageType(level)
end

---Returns how many kills remain until the next mini-boss, boss or new location.
-- @param startLevel number starting level
-- @return number killsNeeded
-- @return number milestoneLevel
-- @return string milestoneType
function LevelSystem:getKillsUntilMilestone(startLevel)
    local lvl = startLevel or self.currentLevel
    local kills = math.max(0, (self.requiredKills or 0) - (self.killCount or 0))
    local mLevel = lvl
    local t = "normal"
    repeat
        mLevel = mLevel + 1
        t = self.getStageType(mLevel)
        kills = kills + self:getKillRequirement(mLevel)
    until t == "mini" or t == "boss" or t == "location" or mLevel > lvl + 100
    return kills, mLevel, t
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
    broadcastProgress()
end

---Ensures a new wave is spawned whenever all enemies are defeated.
--  This keeps gameplay flowing on early floors where only a few foes spawn.
--  Called every frame by ``GameManager``.
function LevelSystem:update()
    -- Do nothing if the player already cleared this stage
    if self.killCount >= self.requiredKills then
        return
    end
    -- Spawn another wave when no enemies remain (server only)
    if RunService:IsServer() and #EnemySystem.enemies == 0 then
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
    -- Use the exposed method for reliability across environments
    local stageType = self.getStageType(nextLevel)

    if stageType == "location" then
        local nextIndex = (LocationSystem.currentIndex or 1) + 1
        if not LocationSystem:isUnlocked(nextIndex, PlayerLevelSystem.level) then
            return nil
        end
        if not KeySystem:useKey("location") then
            return nil
        end
        LocationSystem:advance()
        local loc = LocationSystem:getCurrent()
        if loc and loc.coordinates and PlayerSystem and PlayerSystem.setPosition then
            PlayerSystem:setPosition(loc.coordinates)
        end
        if RunService:IsServer() and TeleportSystem and TeleportSystem.teleportLocation then
            local players = {}
            local ok, playerService = pcall(function()
                return game:GetService("Players")
            end)
            if ok and playerService then
                players = playerService:GetPlayers()
            end
            TeleportSystem:teleportLocation(loc and loc.placeId or 0, players)
        end
    end

    self.currentLevel = nextLevel
    self.killCount = 0
    self.requiredKills = self:getKillRequirement(self.currentLevel)
    self:scaleStats(self.currentLevel)
    updateWaveSize()

    -- Record the highest stage cleared which is the previous level.
    if self.currentLevel - 1 > self.highestClearedStage then
        self.highestClearedStage = self.currentLevel - 1
    end

    self:strengthenMonsters(stageType)

    -- Determine what kind of enemy encounter should occur on this level.
    if RunService:IsServer() then
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
    end
    EventManager:Get("LevelAdvance"):Fire(self.currentLevel, stageType)
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("StageAdvance", self.currentLevel, stageType)
    end
    broadcastProgress()
    return self.currentLevel
end

---Handles player death and rolls back when dying to a mini-boss.
function LevelSystem:onPlayerDeath()
    local lvl = self.currentLevel
    -- Roll back only on mini-boss stages which occur every 5th level
    -- except when it is also a boss or strong boss stage.
    local rolledBack = false
    if lvl % 5 == 0 and lvl % 10 ~= 0 then
        self.currentLevel = math.max(lvl - 1, 1)
        self.killCount = 0
        self.requiredKills = self:getKillRequirement(self.currentLevel)
        updateWaveSize()
        rolledBack = true
    end
    EventManager:Get("PlayerDeath"):Fire(lvl)
    broadcastProgress()
    if rolledBack and NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("StageRollback", self.currentLevel)
    end
end

function LevelSystem:saveData()
    return {
        currentLevel = self.currentLevel,
        killCount = self.killCount,
        requiredKills = self.requiredKills,
        highest = self.highestClearedStage,
    }
end

function LevelSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.currentLevel) == "number" then
        self.currentLevel = data.currentLevel
    end
    if type(data.killCount) == "number" then
        self.killCount = data.killCount
    end
    if type(data.requiredKills) == "number" then
        self.requiredKills = data.requiredKills
    else
        self.requiredKills = self:getKillRequirement(self.currentLevel)
    end
    if type(data.highest) == "number" then
        self.highestClearedStage = data.highest
    end
    updateWaveSize()
end

return LevelSystem
