-- ServerGameManager.lua
-- Provides access to the full GameManager implementation on the server only.

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("ServerGameManager can only be required on the server", 2)
end

local GameManager = require(script.Parent:WaitForChild("GameManager"))

return GameManager
