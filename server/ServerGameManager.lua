-- ServerGameManager.lua
-- Provides access to the full GameManager implementation on the server only.

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("ServerGameManager can only be required on the server", 2)
end

local src = script.Parent.Parent:WaitForChild("src")
local GameManager = require(src:WaitForChild("GameManager"))

-- Extend GachaSystem with server-only methods
local extendGacha = require(script.Parent:WaitForChild("GachaServer"))
extendGacha(src)

-- Attach server-only functionality
local extend = require(script.Parent:WaitForChild("ServerGameExtensions"))
extend(GameManager, src)

return GameManager
