local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("LevelSystem.server"))
else
    return require(script.Parent:WaitForChild("LevelSystem.client"))
end
