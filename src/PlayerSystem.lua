local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("PlayerSystem.server"))
else
    return require(script.Parent:WaitForChild("PlayerSystem.client"))
end
