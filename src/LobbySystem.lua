-- LobbySystem.lua
-- Handles a shared lobby area where players can meet and trade items.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local LobbySystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    lobbyCoordinates = {x = -200, y = 0, z = 0},
    activePlayers = {},
    returnPositions = {},
    playerSystem = nil,
    teleportSystem = nil,
}

local Players = game:GetService("Players")

function LobbySystem:start(playerSys)
    self.playerSystem = playerSys or self.playerSystem or require(script.Parent:WaitForChild("PlayerSystem"))
    local RunService = game:GetService("RunService")
    if RunService and RunService:IsServer() then
        local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
        self.teleportSystem = self.teleportSystem or require(serverFolder:WaitForChild("TeleportSystem"))
    end
end

---Moves the given player into the lobby and stores their previous position.
function LobbySystem:enter(player)
    local p = player or (Players and Players.LocalPlayer)
    if not p or self.activePlayers[p] then return end
    if self.playerSystem and self.playerSystem.position then
        self.returnPositions[p] = {
            x = self.playerSystem.position.x,
            y = self.playerSystem.position.y,
            z = self.playerSystem.position.z,
        }
        if self.teleportSystem and self.teleportSystem.lobbyPlaceId ~= 0 then
            self.teleportSystem:teleportLobby({p})
        else
            self.playerSystem:setPosition(self.lobbyCoordinates)
        end
    end
    self.activePlayers[p] = true
end

---Returns the player back to their prior position before entering the lobby.
function LobbySystem:leave(player)
    local p = player or (Players and Players.LocalPlayer)
    if not p or not self.activePlayers[p] then return end
    local pos = self.returnPositions[p]
    self.activePlayers[p] = nil
    self.returnPositions[p] = nil
    if pos and self.playerSystem and self.playerSystem.setPosition then
        if self.teleportSystem and self.teleportSystem.lobbyPlaceId ~= 0 then
            self.teleportSystem:teleportHome({p})
        else
            self.playerSystem:setPosition(pos)
        end
    end
end

---Transfers an item between two item systems to facilitate trading.
-- @param fromSys table source ItemSystem
-- @param index number inventory index in the source
-- @param toSys table target ItemSystem
-- @return boolean success
function LobbySystem:tradeItem(fromSys, index, toSys)
    if not fromSys or not toSys or not fromSys.removeItem or not toSys.addItem then
        return false
    end
    local itm = fromSys:removeItem(index)
    if not itm then return false end
    toSys:addItem(itm)
    return true
end

return LobbySystem
