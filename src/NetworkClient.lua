-- NetworkClient.lua
-- Client wrapper around NetworkSystem that exposes only client-safe methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("NetworkClient should only be required on the client", 2)
end

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local ClientNetwork = {}
for k, v in pairs(NetworkSystem) do
    if k ~= "fireAllClients" and k ~= "fireClient" and k ~= "onServerEvent" then
        ClientNetwork[k] = v
    end
end

return ClientNetwork
