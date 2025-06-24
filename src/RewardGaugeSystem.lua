local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("RewardGaugeSystem.server"))
else
    return require(script.Parent:WaitForChild("RewardGaugeSystem.client"))
end
