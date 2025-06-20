-- PartySystem.lua
-- Manages groups of players for co-op features.

local PartySystem = {}
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

---Active party tables keyed by party id.
PartySystem.parties = {}

---Next id used when creating a new party.
PartySystem.nextId = 1

---Mapping of player references to their party id.
PartySystem.playerParty = {}

---Creates a new party with the given leader.
-- @param leader any player identifier
-- @return number new party id
function PartySystem:createParty(leader)
    local id = self.nextId
    self.nextId = id + 1
    self.parties[id] = {leader = leader, members = {[leader] = true}}
    self.playerParty[leader] = id
    NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    return id
end

---Adds a player into the specified party.
function PartySystem:addMember(id, player)
    local p = self.parties[id]
    if not p or p.members[player] then
        return false
    end
    p.members[player] = true
    self.playerParty[player] = id
    NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    return true
end

---Removes a player from a party and deletes empty parties.
function PartySystem:removeMember(id, player)
    local p = self.parties[id]
    if not p or not p.members[player] then
        return false
    end
    p.members[player] = nil
    self.playerParty[player] = nil
    if next(p.members) == nil then
        self.parties[id] = nil
    end
    NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    return true
end

---Returns the party id for a player.
function PartySystem:getPartyId(player)
    return self.playerParty[player]
end

---Returns a list of members for the party id.
function PartySystem:getMembers(id)
    local p = self.parties[id]
    if not p then
        return {}
    end
    local list = {}
    for member in pairs(p.members) do
        table.insert(list, member)
    end
    return list
end

return PartySystem
