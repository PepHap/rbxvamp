-- TeleportSystem.lua
-- Handles teleporting groups of players between places.

local RunService = game:GetService("RunService")
-- TeleportService APIs are server-only:
-- https://create.roblox.com/docs/reference/engine/classes/TeleportService
if RunService and RunService:IsClient() then
    error("TeleportSystem should only be required on the server", 2)
end

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TeleportSystem = {
    raidPlaceId = 0,
    lobbyPlaceId = 0,
    homePlaceId = game.PlaceId,
}

function TeleportSystem:start()
    if self.homePlaceId == 0 or not self.homePlaceId then
        self.homePlaceId = game.PlaceId
    end
end

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

---Teleports all players in ``members`` to the given ``placeId``.
-- @param placeId number target place identifier
-- @param members table list of ``Player`` objects
function TeleportSystem:teleportToPlace(placeId, members)
    return teleportPartyToPlace(placeId, members)
end

---Teleports a party to the place for a new location when defined.
-- ``placeId`` should match the ``placeId`` field of a location entry.
-- @param placeId number Roblox place id
-- @param members table array of players to teleport
function TeleportSystem:teleportLocation(placeId, members)
    if not placeId or placeId == 0 then
        return false
    end
    return teleportPartyToPlace(placeId, members)
end

-- Backwards compatibility
function TeleportSystem:teleportParty(members)
    return self:teleportRaid(members)
end

return TeleportSystem
