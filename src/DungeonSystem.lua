-- DungeonSystem.lua
-- Handles optional dungeon runs that grant upgrade currency when completed.

local RunService = game:GetService("RunService")
-- Dungeon logic is server controlled only:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("DungeonSystem should only be required on the server", 2)
    end
end

local DungeonSystem = {}

local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local RaidSystem = require(script.Parent:WaitForChild("RaidSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

-- Definition of available dungeons. Each dungeon specifies the key
-- type required to enter, the currency rewarded and the number of
-- enemy kills needed for completion.
DungeonSystem.dungeons = {
    ore = {key = "ore", currency = "ore", kills = 3, reward = 5},
    ether = {key = "skill", currency = "ether", kills = 3, reward = 2},
    crystal = {key = "companion", currency = "crystal", kills = 5, reward = 1},
}

---Currently active dungeon identifier or nil when none is running.
DungeonSystem.active = nil

---Current kill count within the active dungeon.
DungeonSystem.killCount = 0

---Attempts to start the specified dungeon by spending the required key.
-- @param kind string dungeon identifier
-- @return boolean true when the dungeon starts
function DungeonSystem:start(kind)
    local d = self.dungeons[kind]
    if not d then
        return false
    end
    if not KeySystem:useKey(d.key) then
        return false
    end
    self.active = kind
    self.killCount = 0
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("DungeonState", self.active, self.killCount, d.kills)
        NetworkSystem:fireAllClients("DungeonProgress", self.killCount, d.kills, self.active)
    end
    return true
end

---Adds a kill toward the dungeon goal and completes if reached.
function DungeonSystem:addKill()
    if not self.active then
        return
    end
    local d = self.dungeons[self.active]
    self.killCount = self.killCount + 1
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("DungeonProgress", self.killCount, d.kills, self.active)
    end
    if self.killCount >= d.kills then
        self:complete()
    end
end

---Awards the dungeon reward and clears the active state.
-- @return boolean true when completion succeeded
function DungeonSystem:complete()
    local kind = self.active
    if not kind then
        return false
    end
    local d = self.dungeons[kind]
    CurrencySystem:add(d.currency, d.reward)
    self.active = nil
    self.killCount = 0
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("DungeonState", nil, 0, 0)
    end
    return true
end

---Aborts the current dungeon without granting rewards.
function DungeonSystem:abort()
    self.active = nil
    self.killCount = 0
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("DungeonState", nil, 0, 0)
    end
end

---Proxy called when an enemy is killed to track dungeon progress.
function DungeonSystem:onEnemyKilled(enemy)
    self:addKill()
    if RaidSystem and RaidSystem.onEnemyKilled then
        RaidSystem:onEnemyKilled(enemy)
    end
end

return DungeonSystem
