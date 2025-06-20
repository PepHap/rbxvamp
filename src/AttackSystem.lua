-- AttackSystem.lua
-- Processes player attack requests on the server to prevent cheating.

local AttackSystem = {}

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local LootSystem = require(script.Parent:WaitForChild("LootSystem"))
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))

AttackSystem.damage = 1
AttackSystem.range = 5

function AttackSystem:start()
    NetworkSystem:onServerEvent("PlayerAttack", function(player)
        AttackSystem:handleAttack(player)
    end)
end

function AttackSystem:handleAttack(player)
    local pos = PlayerSystem.position
    if not pos then return end
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then return end
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= (self.range or 5) * (self.range or 5) then
        local dmg = self.damage or 1
        if target.armor and target.armor > 0 then
            if target.armor >= dmg then
                target.armor = target.armor - dmg
                dmg = 0
            else
                dmg = dmg - target.armor
                target.armor = 0
            end
        end
        target.health = target.health - dmg
        if target.health <= 0 then
            for i, e in ipairs(EnemySystem.enemies) do
                if e == target then
                    table.remove(EnemySystem.enemies, i)
                    NetworkSystem:fireAllClients("EnemyRemove", target.name)
                    break
                end
            end
            LevelSystem:addKill()
            DungeonSystem:onEnemyKilled(target)
            LootSystem:onEnemyKilled(target)
        else
            NetworkSystem:fireAllClients("EnemyUpdate", target.name, target.position, target.health, target.armor)
        end
    end
end

return AttackSystem
