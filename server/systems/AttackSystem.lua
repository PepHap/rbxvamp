-- AttackSystem.lua
-- Processes player attack requests on the server to prevent cheating.

local RunService = game:GetService("RunService")
-- Ensure this module only runs on the server as recommended by Roblox:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("AttackSystem should only be required on the server", 2)
    end
end

local AttackSystem = {}

-- Maximum allowed damage per attack to mitigate exploit attempts
AttackSystem.maxDamage = 20

local src = script.Parent.Parent.Parent:WaitForChild("src")
local server = script.Parent

local NetworkSystem = require(src:WaitForChild("NetworkSystem"))
local EnemySystem = require(server:WaitForChild("EnemySystem"))
local LevelSystem = require(src:WaitForChild("LevelSystem"))
local DungeonSystem = require(server:WaitForChild("DungeonSystem"))
local PlayerSystem = require(script.Parent.Parent:WaitForChild("ServerPlayerSystem"))
local EventManager = require(src:WaitForChild("EventManager"))
local AntiCheatSystem = require(server:WaitForChild("AntiCheatSystem"))
local LoggingSystem = require(server:WaitForChild("LoggingSystem"))

AttackSystem.damage = 1
AttackSystem.range = 5

function AttackSystem:start()
    NetworkSystem:onServerEvent("PlayerAttack", function(player)
        AttackSystem:handleAttack(player)
    end)
end

-- Validates that the player instance is actually part of the game
local function isValidPlayer(player)
    if typeof and typeof(player) == "Instance" then
        local ok, isPlayer = pcall(function()
            return player:IsA("Player")
        end)
        return ok and isPlayer and player.Parent ~= nil
    end
    return false
end

function AttackSystem:handleAttack(player)
    if not isValidPlayer(player) then
        LoggingSystem:logAction("invalid_attack", {player = player})
        return
    end
    AntiCheatSystem:recordAttack(player)
    local pos = PlayerSystem.position
    if not pos then return end
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then return end
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= (self.range or 5) * (self.range or 5) then
        local dmg = self.damage or 1
        if dmg > self.maxDamage then
            LoggingSystem:logAction("suspicious_damage", {player = player, damage = dmg})
            dmg = self.maxDamage
        end
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
            EventManager:Get("EnemyDefeated"):Fire(target)
        else
            NetworkSystem:fireAllClients("EnemyUpdate", target.name, target.position, target.health, target.armor)
        end
    end
end

return AttackSystem
