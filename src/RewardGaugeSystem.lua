local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

-- Provide a basic fallback when the child module is unavailable
if not mod then
    warn("RewardGaugeSystem child module missing; using fallback implementation")
    mod = {
        gauge = 0,
        maxGauge = 100,
        optionCount = 3,
        rerollCost = 1,
        options = nil,
        getPercent = function(self)
            if self.maxGauge <= 0 then return 0 end
            return self.gauge / self.maxGauge
        end,
        getOptions = function(self) return self.options end,
        saveData = function(self) return {gauge = self.gauge} end,
        loadData = function(self, data)
            if type(data) == "table" and type(data.gauge) == "number" then
                self.gauge = data.gauge
            end
        end,
    }
end

return mod
