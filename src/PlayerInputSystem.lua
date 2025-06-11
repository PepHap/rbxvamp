-- PlayerInputSystem.lua
-- Allows manual player control and attacks when auto-battle is disabled.

local PlayerInputSystem = {
    ---When true and running inside Roblox, connects to UserInputService.
    useRobloxObjects = false,
    ---Movement speed in studs per second.
    moveSpeed = 5,
    ---Damage dealt per manual attack.
    damage = 1,
    ---Table of currently held keys.
    keyStates = {},
    ---Reference to the player's position table.
    playerPosition = nil,
}

local PlayerSystem = require("src.PlayerSystem")
local EnemySystem = require("src.EnemySystem")
local LevelSystem = require("src.LevelSystem")
local LootSystem = require("src.LootSystem")
local AutoBattleSystem = require("src.AutoBattleSystem")
local DungeonSystem = require("src.DungeonSystem")

-- Utility to connect Roblox input events when available
local function connectRoblox()
    if not PlayerInputSystem.useRobloxObjects then
        return
    end
    if game and type(game.GetService) == "function" then
        local ok, UIS = pcall(function()
            return game:GetService("UserInputService")
        end)
        if ok and UIS then
            UIS.InputBegan:Connect(function(input)
                PlayerInputSystem:setKeyState(input.KeyCode.Name, true)
            end)
            UIS.InputEnded:Connect(function(input)
                PlayerInputSystem:setKeyState(input.KeyCode.Name, false)
            end)
        end
    end
end

---Initializes the input system.
function PlayerInputSystem:start()
    self.playerPosition = PlayerSystem.position
    connectRoblox()
end

---Sets the state of a key for manual control.
-- @param key string key code name
-- @param isDown boolean whether the key is pressed
function PlayerInputSystem:setKeyState(key, isDown)
    self.keyStates[key] = isDown and true or false
end

---Performs a manual attack against the nearest enemy.
function PlayerInputSystem:manualAttack()
    local pos = self.playerPosition
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then
        return
    end
    if target.health then
        target.health = target.health - self.damage
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

---Updates the player position and handles attack input.
function PlayerInputSystem:update(dt)
    if AutoBattleSystem.enabled then
        return
    end
    local pos = self.playerPosition
    local step = self.moveSpeed * dt
    if self.keyStates.D or self.keyStates.Right then
        pos.x = pos.x + step
    end
    if self.keyStates.A or self.keyStates.Left then
        pos.x = pos.x - step
    end
    if self.keyStates.W or self.keyStates.Up then
        pos.y = pos.y + step
    end
    if self.keyStates.S or self.keyStates.Down then
        pos.y = pos.y - step
    end
    if self.keyStates.Space then
        self:manualAttack()
        self.keyStates.Space = false
    end
end

return PlayerInputSystem

