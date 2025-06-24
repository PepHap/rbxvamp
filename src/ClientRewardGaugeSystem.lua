-- ClientRewardGaugeSystem.lua
-- Exposes a read-only subset of RewardGaugeSystem for the client.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientRewardGaugeSystem should only be required on the client", 2)
end

local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))

local blacklist = {
    setMaxGauge = true,
    setOptionCount = true,
    setRerollCost = true,
    generateOptions = true,
    addPoints = true,
    choose = true,
    reroll = true,
    resetGauge = true,
    saveData = true,
}

local ClientRewardGaugeSystem = {}
for k, v in pairs(RewardGaugeSystem) do
    if not blacklist[k] then
        ClientRewardGaugeSystem[k] = v
    end
end

return ClientRewardGaugeSystem
