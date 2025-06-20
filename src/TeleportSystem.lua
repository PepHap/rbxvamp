-- TeleportSystem.lua
-- Handles teleporting groups of players between places.

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TeleportSystem = {
    raidPlaceId = 0,
}

---Teleports all players in the array to the raid place using TeleportPartyAsync.
-- @param members table array of Player instances
function TeleportSystem:teleportParty(members)
    if self.raidPlaceId == 0 then
        return false
    end
    if type(members) ~= "table" or #members == 0 then
        return false
    end
    local ok, err = pcall(function()
        TeleportService:TeleportPartyAsync(self.raidPlaceId, members)
    end)
    if not ok then
        warn("Teleport failed", err)
    end
    return ok
end

return TeleportSystem
