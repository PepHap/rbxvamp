-- CompanionAttackSystem.lua
-- Controls companion movement and automatic attacks

local RunService = game:GetService("RunService")
local CompanionAttackSystem = {
    ---Movement speed in studs per second when following the player.
    moveSpeed = 2,
    ---Maximum distance at which a companion will damage an enemy.
    attackRange = 3,
    ---Damage dealt per companion level when attacking.
    damagePerLevel = 1,
    ---Reference to the CompanionSystem storing available companions.
    companionSystem = nil,
    ---Table of position tables for each companion.
    positions = {},
}

local AutoBattleSystem
if RunService:IsServer() then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    AutoBattleSystem = require(serverFolder:WaitForChild("AutoBattleSystem"))
end
local EnemySystem
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))

if RunService:IsServer() then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    EnemySystem = require(serverFolder:WaitForChild("EnemySystem"))
    DungeonSystem = require(serverFolder:WaitForChild("DungeonSystem"))
end
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))

---Initializes companion positions and stores the system reference.
-- @param compSys table optional CompanionSystem instance
function CompanionAttackSystem:start(compSys)
    self.companionSystem = compSys or self.companionSystem or CompanionSystem
    self.positions = {}
    local pos = AutoBattleSystem.playerPosition or {x = 0, y = 0}
    for i, _ in ipairs(self.companionSystem.companions) do
        self.positions[i] = {x = pos.x, y = pos.y}
    end
end

---Adds a companion and creates a matching position entry.
-- @param companion table companion data
function CompanionAttackSystem:addCompanion(companion)
    if not self.companionSystem then
        self.companionSystem = CompanionSystem
    end
    self.companionSystem:add(companion)
    local pos = AutoBattleSystem.playerPosition or {x = 0, y = 0}
    table.insert(self.positions, {x = pos.x, y = pos.y})
end

---Moves companions toward the player and attacks nearby enemies.
-- @param dt number delta time
function CompanionAttackSystem:update(dt)
    if RunService:IsClient() then
        return
    end
    local comps = self.companionSystem and self.companionSystem.companions or {}
    local playerPos = AutoBattleSystem.playerPosition or {x = 0, y = 0}
    for i, comp in ipairs(comps) do
        local pos = self.positions[i]
        if pos then
            -- follow the player
            local dx = playerPos.x - pos.x
            local dy = playerPos.y - pos.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                local step = math.min(self.moveSpeed * dt, dist)
                pos.x = pos.x + dx / dist * step
                pos.y = pos.y + dy / dist * step
            end
            -- attack nearest enemy
            local enemy = EnemySystem:getNearestEnemy(pos)
            if enemy then
                local ex = enemy.position.x - pos.x
                local ey = enemy.position.y - pos.y
                local d2 = ex * ex + ey * ey
                if d2 <= self.attackRange * self.attackRange then
                    local dmg = (comp.level or 1) * self.damagePerLevel
                    enemy.health = enemy.health - dmg
                    if enemy.health <= 0 then
                        for j, e in ipairs(EnemySystem.enemies) do
                            if e == enemy then
                                table.remove(EnemySystem.enemies, j)
                                NetworkSystem:fireAllClients("EnemyRemove", enemy.name)
                                break
                            end
                        end
                        LevelSystem:addKill()
                        DungeonSystem:onEnemyKilled(enemy)
                        EventManager:Get("EnemyDefeated"):Fire(enemy)
                    end
                end
            end
        end
    end
end

return CompanionAttackSystem

