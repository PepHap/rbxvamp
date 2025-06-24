local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("StatUpgradeSystem.server"))
else
    return require(script.Parent:WaitForChild("StatUpgradeSystem.client"))
end
