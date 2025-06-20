-- RaidSystem.lua
-- Handles cooperative raid encounters with tougher enemies.

local RaidSystem = {}

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

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

---Difficulty scaling applied per additional party member
RaidSystem.difficultyPerMember = 0.5

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
    local partyId = self.partySystem and self.partySystem:getPartyId(player)
    local members = partyId and self.partySystem:getMembers(partyId) or {}
    if #members < 2 then
        return false
    end
    if not KeySystem:useKey("raid") then
        return false
    end
    self.active = true
    self.killCount = 0
    local size = #members
    local scale = 1 + math.max(size - 1, 0) * (self.difficultyPerMember or 0)
    EnemySystem.healthScale = (EnemySystem.healthScale or 1) * scale
    EnemySystem.damageScale = (EnemySystem.damageScale or 1) * scale
    EventManager:Get("RaidStart"):Fire()
    NetworkSystem:fireAllClients("RaidStatus", "start", size)
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
end

---Ends the raid when the boss is defeated.
function RaidSystem:onBossKilled()
    if not self.active then
        return
    end
    self.active = false
    EnemySystem.healthScale = 1
    EnemySystem.damageScale = 1
    EventManager:Get("RaidComplete"):Fire()
    NetworkSystem:fireAllClients("RaidStatus", "complete")
end

function RaidSystem:isActive()
    return self.active
end

return RaidSystem
