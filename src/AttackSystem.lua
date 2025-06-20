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
        target.health = target.health - (self.damage or 1)
        if target.health <= 0 then
            for i, e in ipairs(EnemySystem.enemies) do
                if e == target then
                    table.remove(EnemySystem.enemies, i)
                    break
                end
            end
            LevelSystem:addKill()
            DungeonSystem:onEnemyKilled(target)
            LootSystem:onEnemyKilled(target)
        end
    end
end

return AttackSystem
