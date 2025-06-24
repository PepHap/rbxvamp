-- ClientPlayerSystem.lua
-- Provides a client-safe subset of PlayerSystem without server-only methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientPlayerSystem should only be required on the client", 2)
end

local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))

-- Methods that manipulate server state are stripped out for the client.
-- Exclude any functions that would change the authoritative
-- player state on the server. The client should never invoke
-- these methods directly.
local blacklist = {
    onDeath = true,
    takeDamage = true,
    heal = true,
    setPosition = true,
}

local ClientPlayerSystem = {}
for k, v in pairs(PlayerSystem) do
    if not blacklist[k] then
        ClientPlayerSystem[k] = v
    end
end

return ClientPlayerSystem
