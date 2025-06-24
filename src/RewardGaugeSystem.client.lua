-- RewardGaugeSystem.client.lua
-- Client wrapper around RewardGaugeSystem removing server functions.
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
