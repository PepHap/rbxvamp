local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientLevelSystem should only be required on the client", 2)
end

return require(script.Parent:WaitForChild("LevelSystem"))
