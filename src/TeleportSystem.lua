-- TeleportSystem.lua
-- Handles teleporting groups of players between places.

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TeleportSystem = {
    raidPlaceId = 0,
    lobbyPlaceId = 0,
    homePlaceId = game.PlaceId,
}

---Teleports all players in ``members`` to ``placeId`` using
-- ``TeleportPartyAsync``. See Roblox documentation:
-- https://create.roblox.com/docs/reference/engine/classes/TeleportService#TeleportPartyAsync
-- @param placeId number target place identifier
-- @param members table array of ``Player`` instances
local function teleportPartyToPlace(placeId, members)
    if placeId == 0 then
        return false
    end
    if type(members) ~= "table" or #members == 0 then
        return false
    end
    local ok, err = pcall(function()
        TeleportService:TeleportPartyAsync(placeId, members)
    end)
    if not ok then
        warn("Teleport failed", err)
    end
    return ok
end

function TeleportSystem:teleportRaid(members)
    return teleportPartyToPlace(self.raidPlaceId, members)
end

function TeleportSystem:teleportLobby(members)
    return teleportPartyToPlace(self.lobbyPlaceId, members)
end

function TeleportSystem:teleportHome(members)
    return teleportPartyToPlace(self.homePlaceId, members)
end

-- Backwards compatibility
function TeleportSystem:teleportParty(members)
    return self:teleportRaid(members)
end

return TeleportSystem
