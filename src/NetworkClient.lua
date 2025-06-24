-- NetworkClient.lua
-- Provides client-side networking functions using RemoteEvents.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("NetworkClient should only be required on the client", 2)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEventNames = require(script.Parent:WaitForChild("RemoteEventNames"))

local function getEvent(alias)
    local name = RemoteEventNames[alias] or alias
    local folder = ReplicatedStorage:WaitForChild("RemoteEvents")
    return folder:WaitForChild(name)
end

local ClientNetwork = {}

function ClientNetwork:fireServer(name, ...)
    local ev = getEvent(name)
    if ev and ev.FireServer then
        ev:FireServer(...)
    end
end

function ClientNetwork:onClientEvent(name, callback)
    local ev = getEvent(name)
    if ev and ev.OnClientEvent then
        ev.OnClientEvent:Connect(callback)
    end
end

return ClientNetwork
