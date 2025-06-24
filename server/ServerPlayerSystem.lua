-- ServerPlayerSystem.lua
-- Provides access to the full PlayerSystem exclusively on the server.
-- This prevents client scripts from accidentally requiring the server
-- implementation which contains privileged logic.

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("ServerPlayerSystem can only be required on the server", 2)
end

local src = script.Parent.Parent:WaitForChild("src")
local PlayerSystem = require(src:WaitForChild("PlayerSystem"))

return PlayerSystem
