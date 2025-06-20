-- AutoBattleSystem.lua
-- Provides automatic combat actions when enabled.

local RunService = game:GetService("RunService")
local AutoBattleSystem = {}

-- Resolve the EnemySystem path relative to how this module was required. This
-- keeps unit tests functional even when they load modules using relative paths
-- like "../src/AutoBattleSystem".
-- Parent folder containing the other systems
local parent = script.Parent
local EnemySystem = require(parent:WaitForChild("EnemySystem"))
local LevelSystem = require(parent:WaitForChild("LevelSystem"))
local LootSystem = require(parent:WaitForChild("LootSystem"))
local DungeonSystem = require(parent:WaitForChild("DungeonSystem"))
local NetworkSystem = require(parent:WaitForChild("NetworkSystem"))

---Current player position used for simple movement calculations.
AutoBattleSystem.playerPosition = {x = 0, y = 0}

---Movement speed in studs per second used when approaching a target.
AutoBattleSystem.moveSpeed = 1

---Maximum distance at which an attack will occur instead of moving.
AutoBattleSystem.attackRange = 5

---Damage dealt to enemies per attack.
AutoBattleSystem.damage = 1

---Delay between successive attacks when auto battling.
AutoBattleSystem.attackCooldown = 1

---Time remaining before another attack can occur.
AutoBattleSystem.attackTimer = 0

---Reference to the last enemy attacked by the system.
AutoBattleSystem.lastAttackTarget = nil

---Indicates whether auto-battle mode is active.
AutoBattleSystem.enabled = false
AutoBattleSystem.disabledTimer = 0
AutoBattleSystem.wasEnabled = false

function AutoBattleSystem:start()
    if RunService:IsServer() then
        NetworkSystem:onServerEvent("AttackRequest", function(player)
            AutoBattleSystem:manualAttack()
        end)
        NetworkSystem:onServerEvent("SkillRequest", function(player, index)
            if AutoBattleSystem.skillCastSystem and AutoBattleSystem.skillCastSystem.useSkill then
                AutoBattleSystem.skillCastSystem:useSkill(index)
            end
        end)
    end
end

---Enables auto-battle mode.
function AutoBattleSystem:enable()
    self.enabled = true
end

---Disables auto-battle mode.
function AutoBattleSystem:disable()
    self.enabled = false
end

function AutoBattleSystem:disableForDuration(duration)
    local n = tonumber(duration) or 0
    if n <= 0 then return end
    self.wasEnabled = self.enabled
    self.enabled = false
    self.disabledTimer = n
end

function AutoBattleSystem:manualAttack()
    local pos = self.playerPosition
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then return end
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= self.attackRange * self.attackRange then
        self.lastAttackTarget = target
        if target.health then
            target.health = target.health - self.damage
            if target.health <= 0 then
                for i, enemy in ipairs(EnemySystem.enemies) do
                    if enemy == target then
                        table.remove(EnemySystem.enemies, i)
                        break
                    end
                end
                LevelSystem:addKill()
                DungeonSystem:onEnemyKilled(target)
                LootSystem:onEnemyKilled(target)
                self.lastAttackTarget = nil
            end
        end
        self.attackTimer = self.attackCooldown
    end
end

---Updates automatic combat behavior when enabled.
-- @param dt number delta time since last update
function AutoBattleSystem:update(dt)
    if RunService:IsClient() then
        return
    end
    if self.disabledTimer and self.disabledTimer > 0 then
        self.disabledTimer = self.disabledTimer - dt
        if self.disabledTimer <= 0 and self.wasEnabled then
            self.enabled = true
        end
    end
    if not self.enabled then
        return
    end
    self.attackTimer = math.max(0, (self.attackTimer or 0) - dt)
    local pos = self.playerPosition
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then
        return
    end

    -- Target tables store coordinates within the `position` field
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= self.attackRange * self.attackRange and self.attackTimer <= 0 then
        -- Target is within attack range, register an attack
        self.lastAttackTarget = target
        if target.health then
            target.health = target.health - self.damage
            if target.health <= 0 then
                for i, enemy in ipairs(EnemySystem.enemies) do
                    if enemy == target then
                        table.remove(EnemySystem.enemies, i)
                        NetworkSystem:fireAllClients("EnemyRemove", target.name)
                        break
                    end
                end
                LevelSystem:addKill()
                DungeonSystem:onEnemyKilled(target)
                LootSystem:onEnemyKilled(target)
                self.lastAttackTarget = nil
            end
        end
        self.attackTimer = self.attackCooldown
    else
        -- Move toward the target by a small step based on moveSpeed
        local dist = math.sqrt(distSq)
        if dist > 0 then
            local step = math.min(self.moveSpeed * dt, dist)
            pos.x = pos.x + dx / dist * step
            pos.y = pos.y + dy / dist * step
        end
        self.lastAttackTarget = nil
    end
end

return AutoBattleSystem
