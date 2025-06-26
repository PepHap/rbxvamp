-- PartySystem.lua
-- Manages groups of players for co-op features.

local RunService = game:GetService("RunService")
-- Party logic involves teleporting players and should run on the server:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService:IsClient() then
    error("PartySystem should only be required on the server", 2)
end

local PartySystem = {}
local server = script.Parent
local src = script.Parent.Parent.Parent:WaitForChild("src")
local NetworkSystem = require(src:WaitForChild("NetworkServer"))
local LobbySystem = require(src:WaitForChild("LobbySystem"))
local TeleportSystem = require(server:WaitForChild("TeleportSystem"))
local Players = game:GetService("Players")

---Optional teleport system used when removing players from a party.
PartySystem.teleportSystem = TeleportSystem

---Pending invites indexed by invitee player object
PartySystem.invites = {}

---Active party tables keyed by party id.
PartySystem.parties = {}

---Next id used when creating a new party.
PartySystem.nextId = 1

---Maximum number of members in a party.
PartySystem.maxMembers = 4

---Mapping of player references to their party id.
PartySystem.playerParty = {}

-- Tracks players who marked themselves ready for a raid
PartySystem.ready = {}

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

    NetworkSystem:onServerEvent("RaidReady", function(player, ready)
        PartySystem:setReady(player, ready)
    end)

    if Players and Players.PlayerRemoving then
        Players.PlayerRemoving:Connect(function(p)
            local id = PartySystem:getPartyId(p)
            if id then
                PartySystem:removeMember(id, p)
            end
            PartySystem.invites[p] = nil
            PartySystem.ready[p] = nil
            if LobbySystem and LobbySystem.leave then
                LobbySystem:leave(p)
            end
        end)
    end
end

---Creates a new party with the given leader.
-- @param leader any player identifier
-- @return number new party id
function PartySystem:createParty(leader)
    if self.playerParty[leader] then
        self:removeMember(self.playerParty[leader], leader)
    end
    local id = self.nextId
    self.nextId = id + 1
    self.parties[id] = {leader = leader, members = {[leader] = true}}
    self.playerParty[leader] = id
    if LobbySystem and LobbySystem.enter then
        LobbySystem:enter(leader)
    end
    NetworkSystem:fireAllClients("RaidReady", leader, false)
    NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    return id
end

---Adds a player into the specified party.
function PartySystem:addMember(id, player)
    local p = self.parties[id]
    if not p then
        NetworkSystem:fireClient(player, "PartyJoinFailed", "invalid")
        return false
    end
    if self.playerParty[player] and self.playerParty[player] ~= id then
        NetworkSystem:fireClient(player, "PartyJoinFailed", "member")
        return false
    end
    if p.members[player] then
        NetworkSystem:fireClient(player, "PartyJoinFailed", "member")
        return false
    end
    local count = 0
    for _ in pairs(p.members) do
        count = count + 1
    end
    if count >= (self.maxMembers or 4) then
        NetworkSystem:fireClient(player, "PartyJoinFailed", "full")
        return false
    end
    p.members[player] = true
    self.playerParty[player] = id
    if LobbySystem and LobbySystem.enter then
        LobbySystem:enter(player)
    end
    NetworkSystem:fireAllClients("RaidReady", player, false)
    NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    return true
end

---Sends an invite from one player to another.
function PartySystem:sendInvite(fromPlayer, toPlayer)
    if not fromPlayer or not toPlayer then return end
    local id = self:getPartyId(fromPlayer)
    if id then
        local p = self.parties[id]
        if p then
            local count = 0
            for _ in pairs(p.members) do count = count + 1 end
            if count >= (self.maxMembers or 4) then
                NetworkSystem:fireClient(fromPlayer, "PartyJoinFailed", "full")
                return
            end
        end
    end
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
    self.ready[player] = nil
    if LobbySystem and LobbySystem.leave then
        LobbySystem:leave(player)
    end
    if self.teleportSystem and self.teleportSystem.teleportHome then
        self.teleportSystem:teleportHome({player})
    end
    NetworkSystem:fireAllClients("RaidReady", player, false)
    if next(p.members) == nil then
        self.parties[id] = nil
        NetworkSystem:fireAllClients("PartyDisband", id)
    else
        NetworkSystem:fireAllClients("PartyUpdated", id, self:getMembers(id))
    end
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

---Sets the ready state for a player and notifies clients.
function PartySystem:setReady(player, ready)
    if ready then
        self.ready[player] = true
    else
        self.ready[player] = nil
    end
    local id = self:getPartyId(player)
    if id then
        NetworkSystem:fireAllClients("RaidReady", player, self.ready[player] and true or false)
    end
end

---Returns true if all members of the party marked themselves ready.
function PartySystem:allReady(id)
    local p = self.parties[id]
    if not p then return false end
    for member in pairs(p.members) do
        if not self.ready[member] then
            return false
        end
    end
    return true
end

return PartySystem
