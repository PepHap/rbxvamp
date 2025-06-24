local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("GachaSystem.server"))
else
    return require(script.Parent:WaitForChild("ClientGachaSystem"))
end
