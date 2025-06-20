-- RaidSystem.lua
-- Handles cooperative raid encounters with tougher enemies.

local RaidSystem = {}

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

function RaidSystem:start()
    EventManager:Get("EnemyKilled"):Connect(function(enemy)
        RaidSystem:onEnemyKilled(enemy)
    end)
    EventManager:Get("BossKilled"):Connect(function(enemy)
        RaidSystem:onBossKilled(enemy)
    end)
end

---Begins a raid if the party has the required key.
function RaidSystem:startRaid()
    if self.active then
        return false
    end
    if not KeySystem:useKey("raid") then
        return false
    end
    self.active = true
    self.killCount = 0
    EnemySystem.healthScale = (EnemySystem.healthScale or 1) * 1.5
    EnemySystem.damageScale = (EnemySystem.damageScale or 1) * 1.5
    EventManager:Get("RaidStart"):Fire()
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
end

function RaidSystem:isActive()
    return self.active
end

return RaidSystem
