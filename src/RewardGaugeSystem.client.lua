local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("RewardGaugeSystem.client should only be required on the client", 2)
end

local RewardGaugeSystem = {}
RewardGaugeSystem.gauge = 0
RewardGaugeSystem.maxGauge = 100
RewardGaugeSystem.optionCount = 3
RewardGaugeSystem.rerollCost = 1
RewardGaugeSystem.options = nil

function RewardGaugeSystem:getPercent()
    if self.maxGauge <= 0 then
        return 0
    end
    return self.gauge / self.maxGauge
end

function RewardGaugeSystem:getOptions()
    return self.options
end

function RewardGaugeSystem:saveData()
    return {gauge = self.gauge}
end

function RewardGaugeSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.gauge) == "number" then
        self.gauge = data.gauge
    end
end

return RewardGaugeSystem
