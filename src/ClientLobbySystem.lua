-- ClientLobbySystem.lua
-- Provides client-side access to lobby actions via RemoteEvents.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientLobbySystem should only be required on the client", 2)
end

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local ClientLobbySystem = {}

---Requests to enter the lobby.
function ClientLobbySystem:enter()
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("LobbyRequest", "enter")
    end
end

---Requests to leave the lobby.
function ClientLobbySystem:leave()
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("LobbyRequest", "leave")
    end
end

return ClientLobbySystem
