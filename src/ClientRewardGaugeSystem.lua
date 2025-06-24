local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientRewardGaugeSystem should only be required on the client", 2)
end

return require(script.Parent:WaitForChild("RewardGaugeSystem.client"))
