-- ClientPlayerSystem.lua
-- Provides a client-safe subset of PlayerSystem without server-only methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientPlayerSystem should only be required on the client", 2)
end

local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))

-- Methods that manipulate server state are stripped out for the client.
local blacklist = {
    onDeath = true,
}

local ClientPlayerSystem = {}
for k, v in pairs(PlayerSystem) do
    if not blacklist[k] then
        ClientPlayerSystem[k] = v
    end
end

return ClientPlayerSystem
