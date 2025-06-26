-- NetworkSystem.lua
-- Provides RemoteEvent based messaging between the server and clients.
-- RemoteEvents are stored in ReplicatedStorage as recommended in the Roblox documentation:
-- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local RemoteEventNames = require(script.Parent:WaitForChild("RemoteEventNames"))
local RunService = game:GetService("RunService")

local NetworkSystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    events = {},
    allowedEvents = {},
    adminIds = {},
    adminEvents = {}
}

local ReplicatedStorage

-- Ensures a single RemoteEvent exists per name inside ReplicatedStorage.
-- Removes duplicates that may remain from previous sessions.
local function createRemoteEvent(alias)
    local realName = RemoteEventNames[alias] or alias
    if not NetworkSystem.useRobloxObjects then
        return EventManager:Get(realName)
    end
    ReplicatedStorage = ReplicatedStorage or game:GetService("ReplicatedStorage")
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end
    local ev = folder:FindFirstChild(realName)
    if not ev then
        ev = Instance.new("RemoteEvent")
        ev.Name = realName
        ev.Parent = folder
    else
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name == realName and child ~= ev and child.Destroy then
                child:Destroy()
            end
        end
    end
    return ev
end

function NetworkSystem:start()
    -- Remove stale events from previous sessions
    if self.cleanup then
        self:cleanup()
    end
    -- List of event aliases created by the system
    local aliases = {
        "PartyUpdated", "RaidStatus", "RaidEvent", "RaidReward", "PartyInvite",
        "PartyResponse", "PartyDisband", "PartyJoinFailed", "PlayerState",
        "RaidReady", "LevelProgress", "CurrencyUpdate", "PlayerLevelUpdate",
        "GaugeUpdate", "GaugeOptions", "GaugeReset", "RewardChoice",
        "RewardResult", "ScoreboardUpdate", "DungeonRequest", "DungeonState",
        "DungeonProgress", "PlayerLevelUp", "StageAdvance", "StageRollback",
        "RewardReroll", "EnemySpawn", "EnemyRemove", "EnemyUpdate",
        "SalvageRequest", "SalvageResult", "PlayerAttack", "PartyRequest",
        "RaidRequest", "AttackRequest", "SkillRequest", "SkillCooldown", "QuestUpdate",
        "QuestData", "QuestRequest", "QuestClaim", "PlayerDied", "GachaRequest", "GachaResult",
        "ExchangeRequest", "ExchangeResult", "StatUpgradeRequest", "StatUpdate",
        "AutoBattleToggle", "LobbyRequest"
    }
    for _, alias in ipairs(aliases) do
        self.events[alias] = createRemoteEvent(alias)
    end

    for name in pairs(RemoteEventNames) do
        self.allowedEvents[name] = true
    end
end

function NetworkSystem:setAdminIds(ids)
    if type(ids) == "table" then
        self.adminIds = ids
    end
end

---Registers a RemoteEvent name that should only be fired by admins.
-- The event will still be created if needed.
-- @param name string event alias
function NetworkSystem:registerAdminEvent(name)
    if not name then return end
    self.adminEvents[name] = true
    self.allowedEvents[name] = true
    if not self.events[name] then
        self.events[name] = createRemoteEvent(name)
    end
end

function NetworkSystem:isAdmin(player)
    if typeof and typeof(player) == "Instance" then
        local uid = player.UserId
        for _, id in ipairs(self.adminIds) do
            if id == uid then
                return true
            end
        end
    end
    return false
end

function NetworkSystem:getEvent(name)
    if self.allowedEvents[name] then
        if not self.events[name] then
            self.events[name] = createRemoteEvent(name)
        end
        return self.events[name]
    end
    return nil
end

-- Destroys all RemoteEvents created by this system so they do not
-- persist across rounds or sessions.
function NetworkSystem:cleanup()
    if not self.useRobloxObjects then
        self.events = {}
        return
    end
    ReplicatedStorage = ReplicatedStorage or game:GetService("ReplicatedStorage")
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if folder then
        for name, ev in pairs(self.events) do
            if ev and ev.Destroy and ev:IsDescendantOf(folder) then
                ev:Destroy()
            end
            self.events[name] = nil
        end
    else
        self.events = {}
    end
end

-- Fires a RemoteEvent to all connected clients. Per Roblox API this
-- method can only be called from the server. When executed on the
-- client we fall back to ``Fire`` so tests or client code do not
-- raise an error.
-- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent#FireAllClients
function NetworkSystem:fireAllClients(name, ...)
    local ev = self:getEvent(name)
    if not ev then return end
    if RunService and RunService:IsServer() then
        if ev and ev.FireAllClients then
            ev:FireAllClients(...)
        end
    else
        local hasFire = false
        if ev then
            local ok, val = pcall(function()
                return ev.Fire
            end)
            if ok and val then
                hasFire = true
            end
        end
        if hasFire then
            -- Fallback for test environments using BindableEvents
            ev:Fire(...)
        end
    end
end

function NetworkSystem:fireClient(player, name, ...)
    local ev = self:getEvent(name)
    if not ev then return end
    if ev and ev.FireClient then
        ev:FireClient(player, ...)
    elseif ev and ev.Fire then
        ev:Fire(...)
    end
end

-- Sends an event only to a specific admin player.
function NetworkSystem:fireClientAdmin(player, name, ...)
    if not self:isAdmin(player) then
        return
    end
    self:fireClient(player, name, ...)
end

function NetworkSystem:fireServer(name, ...)
    local ev = self:getEvent(name)
    if not ev then return end
    if ev and ev.FireServer then
        ev:FireServer(...)
    elseif ev and ev.Fire then
        ev:Fire(...)
    end
end

function NetworkSystem:onServerEvent(name, callback, adminOnly)
    local ev = self:getEvent(name)
    if not ev then return end
    if ev and ev.OnServerEvent then
        ev.OnServerEvent:Connect(function(player, ...)
            if typeof(player) ~= "Instance" or not player:IsA("Player") then
                return
            end
            if adminOnly or self.adminEvents[name] then
                if not self:isAdmin(player) then
                    return
                end
            end
            callback(player, ...)
        end)
    elseif ev and ev.Connect then
        ev:Connect(callback)
    end
end

---Connects to a RemoteEvent that only admins may trigger.
-- @param name string event alias
-- @param callback function handler
function NetworkSystem:onServerEventAdmin(name, callback)
    self:onServerEvent(name, callback, true)
end

function NetworkSystem:onClientEvent(name, callback)
    local ev = self:getEvent(name)
    if not ev then return end
    if ev and ev.OnClientEvent then
        ev.OnClientEvent:Connect(callback)
    elseif ev and ev.Connect then
        ev:Connect(callback)
    end
end

-- Remove inappropriate methods depending on context so the client can't
-- invoke server-only functionality and vice versa. The Roblox API restricts
-- certain RemoteEvent methods to a specific environment. Stripping the
-- functions ensures an exploiter cannot misuse them locally.
if RunService:IsClient() then
    NetworkSystem.fireAllClients = nil
    NetworkSystem.onServerEvent = nil
elseif RunService:IsServer() then
    -- The server never needs to call FireServer or listen to OnClientEvent
    NetworkSystem.fireServer = nil
    NetworkSystem.onClientEvent = nil
end

return NetworkSystem
