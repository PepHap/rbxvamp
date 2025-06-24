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
    events = {}
}

local ReplicatedStorage

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
    end
    return ev
end

function NetworkSystem:start()
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
        "QuestData", "QuestRequest", "PlayerDied", "GachaRequest", "GachaResult",
        "ExchangeRequest", "ExchangeResult", "StatUpgradeRequest", "StatUpdate"
    }
    for _, alias in ipairs(aliases) do
        self.events[alias] = createRemoteEvent(alias)
    end
end

function NetworkSystem:getEvent(name)
    return self.events[name] or createRemoteEvent(name)
end

-- Fires a RemoteEvent to all connected clients. Per Roblox API this
-- method can only be called from the server. When executed on the
-- client we fall back to ``Fire`` so tests or client code do not
-- raise an error.
-- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent#FireAllClients
function NetworkSystem:fireAllClients(name, ...)
    local ev = self:getEvent(name)
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
