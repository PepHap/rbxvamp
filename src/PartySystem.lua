-- PartySystem.lua
-- Manages groups of players for co-op features.

local PartySystem = {}
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local Players = game:GetService("Players")

---Pending invites indexed by invitee player object
PartySystem.invites = {}

---Active party tables keyed by party id.
PartySystem.parties = {}

---Next id used when creating a new party.
PartySystem.nextId = 1

---Mapping of player references to their party id.
PartySystem.playerParty = {}

function PartySystem:start()
    NetworkSystem:onServerEvent("PartyRequest", function(player, action, ...)
        if action == "create" then
            local id = PartySystem:createParty(player)
            NetworkSystem:fireClient(player, "PartyUpdated", id, PartySystem:getMembers(id))
        elseif action == "join" then
            local id = ...
            if PartySystem:addMember(id, player) then
                NetworkSystem:fireAllClients("PartyUpdated", id, PartySystem:getMembers(id))
            end
        elseif action == "leave" then
            local id = PartySystem:getPartyId(player)
            if id then
                PartySystem:removeMember(id, player)
            end
        end
    end)

    NetworkSystem:onServerEvent("PartyInvite", function(player, targetName)
        if not targetName or targetName == "" then return end
        local target
        if typeof(targetName) == "Instance" then
            target = targetName
        elseif Players then
            target = Players:FindFirstChild(tostring(targetName))
        end
        if target then
            PartySystem:sendInvite(player, target)
        end
    end)

    NetworkSystem:onServerEvent("PartyResponse", function(player, response)
        PartySystem:respondInvite(player, response == "accept")
    end)

    if Players and Players.PlayerRemoving then
        Players.PlayerRemoving:Connect(function(p)
            local id = PartySystem:getPartyId(p)
            if id then
                PartySystem:removeMember(id, p)
            end
            PartySystem.invites[p] = nil
        end)
    end
end

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

---Sends an invite from one player to another.
function PartySystem:sendInvite(fromPlayer, toPlayer)
    if not fromPlayer or not toPlayer then return end
    self.invites[toPlayer] = fromPlayer
    NetworkSystem:fireClient(toPlayer, "PartyInvite", fromPlayer)
end

---Handles a player response to an invite.
function PartySystem:respondInvite(player, accept)
    local inviter = self.invites[player]
    self.invites[player] = nil
    if not inviter then return end
    if accept then
        local id = self:getPartyId(inviter)
        if not id then
            id = self:createParty(inviter)
        end
        self:addMember(id, player)
    end
    NetworkSystem:fireClient(inviter, "PartyResponse", player, accept and "accept" or "decline")
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
