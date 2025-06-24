local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return require(script.Parent:WaitForChild("PlayerLevelSystem.server"))
else
    return require(script.Parent:WaitForChild("PlayerLevelSystem.client"))
end
