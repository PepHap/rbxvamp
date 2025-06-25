local RunService = game:GetService("RunService")

-- Provide a minimal interface on the client to avoid missing module errors.
-- The real implementation lives in server/systems/AutoBattleSystem.lua
-- and is loaded only on the server.

if RunService:IsServer() then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    return require(serverFolder:WaitForChild("AutoBattleSystem"))
else
    return { enabled = false }
end
