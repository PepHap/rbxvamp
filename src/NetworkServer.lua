-- NetworkServer.lua
-- Server wrapper around NetworkSystem that excludes client-only methods.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
    error("NetworkServer should only be required on the server", 2)
end

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local ServerNetwork = {}
for k, v in pairs(NetworkSystem) do
    if k ~= "fireServer" and k ~= "onClientEvent" then
        ServerNetwork[k] = v
    end
end

return ServerNetwork
