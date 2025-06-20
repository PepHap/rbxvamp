-- RaidSystem.lua
-- Handles cooperative raid encounters with tougher enemies.

local RaidSystem = {}

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local TeleportSystem = require(script.Parent:WaitForChild("TeleportSystem"))
local LobbySystem = require(script.Parent:WaitForChild("LobbySystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local SlotConstants = require(script.Parent:WaitForChild("SlotConstants"))
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))

local EventManager = require(script.Parent:WaitForChild("EventManager"))
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))

---Reference to the PartySystem for group data.
RaidSystem.partySystem = nil

---Indicates if a raid is currently active.
RaidSystem.active = false

---Kill counter used to trigger the raid boss.
RaidSystem.killCount = 0

---Number of kills required before spawning a boss.
RaidSystem.killsForBoss = 20

---Crystals granted to each party member when the raid is completed.
RaidSystem.rewardCrystals = 3

---Difficulty scaling applied per additional party member
-- Difficulty scaling applied per additional party member.
-- The value follows the design notes where each extra member
-- increases enemy strength by roughly 30%.
RaidSystem.difficultyPerMember = 0.3

---Previous enemy health scale before starting a raid.
RaidSystem.prevHealthScale = 1

---Previous enemy damage scale before starting a raid.
RaidSystem.prevDamageScale = 1

---Party id currently in a raid.
RaidSystem.currentPartyId = nil

function RaidSystem:start()
    NetworkSystem:onServerEvent("RaidRequest", function(player)
        if player then
            RaidSystem:startRaid(player)
        end
    end)
    EventManager:Get("EnemyKilled"):Connect(function(enemy)
        RaidSystem:onEnemyKilled(enemy)
    end)
    EventManager:Get("BossKilled"):Connect(function(enemy)
        RaidSystem:onBossKilled(enemy)
    end)
end

---Begins a raid if the party has the required key.
function RaidSystem:startRaid(player)
    if self.active then
        return false
    end
    if not PlayerLevelSystem:isUnlocked("raid") then
        return false
    end
    local partyId = self.partySystem and self.partySystem:getPartyId(player)
    local members = partyId and self.partySystem:getMembers(partyId) or {}
    if #members < 2 then
        return false
    end
    for _, m in ipairs(members) do
        if not LobbySystem or not LobbySystem.activePlayers[m] then
            return false
        end
    end
    if self.partySystem and not self.partySystem:allReady(partyId) then
        return false
    end
    if not KeySystem:useKey("raid") then
        return false
    end
    if TeleportSystem and TeleportSystem.teleportRaid then
        TeleportSystem:teleportRaid(members)
    end
    self.currentPartyId = partyId
    self.active = true
    self.killCount = 0
    local size = #members
    local scale = 1 + math.max(size - 1, 0) * (self.difficultyPerMember or 0)
    self.prevHealthScale = EnemySystem.healthScale or 1
    self.prevDamageScale = EnemySystem.damageScale or 1
    EnemySystem.healthScale = self.prevHealthScale * scale
    EnemySystem.damageScale = self.prevDamageScale * scale
    EventManager:Get("RaidStart"):Fire()
    NetworkSystem:fireAllClients("RaidStatus", "start", size)
    NetworkSystem:fireAllClients("RaidEvent", "start", size)
    return true
end

---Updates raid progress when an enemy dies.
function RaidSystem:onEnemyKilled()
    if not self.active then
        return
    end
    self.killCount = self.killCount + 1
    if self.killCount >= self.killsForBoss then
        self.killCount = 0
        EnemySystem:spawnBoss("boss")
    end
    NetworkSystem:fireAllClients("RaidStatus", "progress", self.killCount, self.killsForBoss)
    NetworkSystem:fireAllClients("RaidEvent", "progress", self.killCount, self.killsForBoss)
end

---Ends the raid when the boss is defeated.
function RaidSystem:onBossKilled()
    if not self.active then
        return
    end
    self.active = false
    EnemySystem.healthScale = self.prevHealthScale or 1
    EnemySystem.damageScale = self.prevDamageScale or 1
    self:awardRewards()
    EventManager:Get("RaidComplete"):Fire()
    NetworkSystem:fireAllClients("RaidStatus", "complete")
    NetworkSystem:fireAllClients("RaidEvent", "complete")
    if self.partySystem and self.currentPartyId then
        for _, member in ipairs(self.partySystem:getMembers(self.currentPartyId)) do
            self.partySystem:setReady(member, false)
            if TeleportSystem and TeleportSystem.teleportHome then
                TeleportSystem:teleportHome({member})
            end
        end
        self.currentPartyId = nil
    end
end

---Distributes raid rewards to all party members.
function RaidSystem:awardRewards()
    if not self.partySystem or not self.currentPartyId then
        return
    end
    local members = self.partySystem:getMembers(self.currentPartyId)
    local crystals = self.rewardCrystals or 0
    for _, player in ipairs(members) do
        CurrencySystem:add("crystal", crystals)
        NetworkSystem:fireClient(player, "RaidReward", "crystal", crystals)
        local slot = SlotConstants.list[math.random(#SlotConstants.list)]
        local item = GachaSystem:rollEquipment(slot)
        if item then
            NetworkSystem:fireClient(player, "RaidReward", slot, item.name)
        end
    end
end

function RaidSystem:isActive()
    return self.active
end

return RaidSystem
