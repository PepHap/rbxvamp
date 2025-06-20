-- NetworkSystem.lua
-- Provides RemoteEvent based messaging between the server and clients.
-- RemoteEvents are stored in ReplicatedStorage as recommended in the Roblox documentation:
-- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))

local NetworkSystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    events = {}
}

local ReplicatedStorage

local function createRemoteEvent(name)
    if not NetworkSystem.useRobloxObjects then
        return EventManager:Get(name)
    end
    ReplicatedStorage = ReplicatedStorage or game:GetService("ReplicatedStorage")
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end
    local ev = folder:FindFirstChild(name)
    if not ev then
        ev = Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = folder
    end
    return ev
end

function NetworkSystem:start()
    -- Create default events used by PartySystem and RaidSystem
    self.events.PartyUpdated = createRemoteEvent("PartyUpdated")
    self.events.RaidStatus = createRemoteEvent("RaidStatus")
    self.events.RaidEvent = createRemoteEvent("RaidEvent")
    self.events.RaidReward = createRemoteEvent("RaidReward")
    self.events.PartyInvite = createRemoteEvent("PartyInvite")
    self.events.PartyResponse = createRemoteEvent("PartyResponse")
    self.events.PartyDisband = createRemoteEvent("PartyDisband")
    self.events.PartyJoinFailed = createRemoteEvent("PartyJoinFailed")
    self.events.PlayerState = createRemoteEvent("PlayerState")
    self.events.RaidReady = createRemoteEvent("RaidReady")
    self.events.LevelProgress = createRemoteEvent("LevelProgress")
    self.events.CurrencyUpdate = createRemoteEvent("CurrencyUpdate")
    self.events.GaugeUpdate = createRemoteEvent("GaugeUpdate")
    self.events.GaugeOptions = createRemoteEvent("GaugeOptions")
    self.events.GaugeReset = createRemoteEvent("GaugeReset")
    self.events.RewardChoice = createRemoteEvent("RewardChoice")
    self.events.RewardResult = createRemoteEvent("RewardResult")

    -- Player level notifications
    self.events.PlayerLevelUp = createRemoteEvent("PlayerLevelUp")

    -- Level progression notifications
    self.events.StageAdvance = createRemoteEvent("StageAdvance")
    self.events.StageRollback = createRemoteEvent("StageRollback")
  
    self.events.RewardReroll = createRemoteEvent("RewardReroll")

    -- Events for synchronizing enemy state with clients
    self.events.EnemySpawn = createRemoteEvent("EnemySpawn")
    self.events.EnemyRemove = createRemoteEvent("EnemyRemove")
    self.events.EnemyUpdate = createRemoteEvent("EnemyUpdate")
    -- Allow clients to request salvaging items on the server
    self.events.SalvageRequest = createRemoteEvent("SalvageRequest")
    self.events.SalvageResult = createRemoteEvent("SalvageResult")
    self.events.PlayerAttack = createRemoteEvent("PlayerAttack")
    -- Events used for client requests
    self.events.PartyRequest = createRemoteEvent("PartyRequest")
    self.events.RaidRequest = createRemoteEvent("RaidRequest")
    -- Combat related requests
    self.events.AttackRequest = createRemoteEvent("AttackRequest")
    self.events.SkillRequest = createRemoteEvent("SkillRequest")
end

function NetworkSystem:getEvent(name)
    return self.events[name] or createRemoteEvent(name)
end

function NetworkSystem:fireAllClients(name, ...)
    local ev = self:getEvent(name)
    if ev and ev.FireAllClients then
        ev:FireAllClients(...)
    elseif ev and ev.Fire then
        ev:Fire(...)
    end
end

function NetworkSystem:fireClient(player, name, ...)
    local ev = self:getEvent(name)
    if ev and ev.FireClient then
        ev:FireClient(player, ...)
    elseif ev and ev.Fire then
        ev:Fire(...)
    end
end

function NetworkSystem:fireServer(name, ...)
    local ev = self:getEvent(name)
    if ev and ev.FireServer then
        ev:FireServer(...)
    elseif ev and ev.Fire then
        ev:Fire(...)
    end
end

function NetworkSystem:onServerEvent(name, callback)
    local ev = self:getEvent(name)
    if ev and ev.OnServerEvent then
        ev.OnServerEvent:Connect(callback)
    elseif ev and ev.Connect then
        ev:Connect(callback)
    end
end

function NetworkSystem:onClientEvent(name, callback)
    local ev = self:getEvent(name)
    if ev and ev.OnClientEvent then
        ev.OnClientEvent:Connect(callback)
    elseif ev and ev.Connect then
        ev:Connect(callback)
    end
end

return NetworkSystem
