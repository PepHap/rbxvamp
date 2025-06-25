local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

if not mod then
    warn("LevelSystem child module missing; using fallback implementation")
    mod = {
        currentLevel = 1,
        killCount = 0,
        requiredKills = 15,
    }
    function mod:getKillRequirement(level)
        level = level or self.currentLevel or 1
        local base = 15
        local locIncrease = math.floor((level - 1) / 30) * 5
        local segmentIncrease = math.floor(((level - 1) % 30) / 10) * 2
        return base + locIncrease + segmentIncrease
    end
    function mod:getPercent()
        if self.requiredKills <= 0 then
            return 0
        end
        return self.killCount / self.requiredKills
    end
    function mod:addKill()
        self.killCount += 1
        if self.killCount >= self.requiredKills then
            self.killCount = 0
            self.currentLevel += 1
            self.requiredKills = self:getKillRequirement(self.currentLevel)
        end
    end
    function mod:saveData()
        return {
            currentLevel = self.currentLevel,
            killCount = self.killCount,
            requiredKills = self.requiredKills,
        }
    end
    function mod:loadData(data)
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
    end
end

return mod
