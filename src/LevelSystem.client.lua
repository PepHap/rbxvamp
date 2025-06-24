local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("LevelSystem client module should only be required on the client", 2)
end

local LevelSystem = {}

local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local WaveConfig = require(script.Parent:WaitForChild("WaveConfig"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))

LevelSystem.highestClearedStage = 0
LevelSystem.currentLevel = 1
LevelSystem.killCount = 0
LevelSystem.requiredKills = 15
LevelSystem.baseWaveSize = 5
LevelSystem.waveSize = LevelSystem.baseWaveSize

local function updateWaveSize()
    LevelSystem.waveSize = LevelSystem.baseWaveSize + math.floor((LevelSystem.currentLevel - 1) / 3)
end

function LevelSystem:getKillRequirement(level)
    level = level or self.currentLevel or 1
    local base = 15
    local locIncrease = math.floor((level - 1) / 30) * 5
    local segmentIncrease = math.floor(((level - 1) % 30) / 10) * 2
    return base + locIncrease + segmentIncrease
end

function LevelSystem:getPercent()
    if self.requiredKills <= 0 then
        return 0
    end
    return self.killCount / self.requiredKills
end

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

function LevelSystem.getStageType(level)
    return getStageType(level)
end

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

function LevelSystem:getNextStageInfo()
    local nextLevel = self.currentLevel + 1
    local killsLeft = math.max(0, (self.requiredKills or 0) - (self.killCount or 0))
    local stageType = self.getStageType(nextLevel)
    local milestoneKills, _, milestoneType = self:getKillsUntilMilestone(self.currentLevel)
    local loc = LocationSystem:getCurrent()
    local bossName
    if loc and loc.bosses then
        bossName = loc.bosses[nextLevel]
    end
    return nextLevel, stageType, killsLeft, bossName, milestoneKills, milestoneType
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
