-- PlayerInputSystem.lua
-- Allows manual player control and attacks when auto-battle is disabled.

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local PlayerInputSystem = {
    ---When true and running inside Roblox, connects to UserInputService.
    useRobloxObjects = detectRoblox(),
    ---Movement speed in studs per second.
    moveSpeed = 5,
    ---Damage dealt per manual attack.
    damage = 1,
    ---Maximum distance at which a manual attack can hit.
    attackRange = 5,
    ---Table of currently held keys.
    keyStates = {},
    ---Reference to the player's position table.
    playerPosition = nil,
    ---Key used to toggle the inventory UI.
    inventoryKey = "B",
    skillKey = "K",
    companionKey = "L",
    gachaKey = "G",
    rewardKey = "R",
    questKey = "J",
    statsKey = "U",
    menuKey = "M",
    adminKey = "F10",
    ---Reference to the SkillCastSystem for manual skill use.
    skillCastSystem = nil,
    ---Mapping from key names to skill slots.
    skillKeyMap = {One = 1, Two = 2, Three = 3, Four = 4},
}

local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local LootSystem = require(script.Parent:WaitForChild("LootSystem"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
local SkillUISystem = require(script.Parent:WaitForChild("SkillUISystem"))
local CompanionUISystem = require(script.Parent:WaitForChild("CompanionUISystem"))
local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
local SkillCastSystem = require(script.Parent:WaitForChild("SkillCastSystem"))
local GachaUISystem = require(script.Parent:WaitForChild("GachaUISystem"))
local RewardGaugeUISystem = require(script.Parent:WaitForChild("RewardGaugeUISystem"))
local StatUpgradeUISystem = require(script.Parent:WaitForChild("StatUpgradeUISystem"))
local QuestUISystem = require(script.Parent:WaitForChild("QuestUISystem"))
local AdminConsoleSystem = require(script.Parent:FindFirstChild("AdminConsoleSystem"))

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
                local name = input.KeyCode.Name
                PlayerInputSystem:setKeyState(name, true)
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
    self.skillCastSystem = self.skillCastSystem or SkillCastSystem
    connectRoblox()
end

---Sets the state of a key for manual control.
-- @param key string key code name
-- @param isDown boolean whether the key is pressed
function PlayerInputSystem:setKeyState(key, isDown)
    self.keyStates[key] = isDown and true or false
    if key == self.inventoryKey and isDown then
        MenuUISystem:openTab("Inventory")
    elseif key == self.skillKey and isDown then
        MenuUISystem:openTab("Skills")
    elseif key == self.companionKey and isDown then
        CompanionUISystem:toggle()
    elseif key == self.gachaKey and isDown then
        GachaUISystem:toggle()
    elseif key == self.rewardKey and isDown then
        RewardGaugeUISystem:toggle()
    elseif key == self.questKey and isDown then
        QuestUISystem:toggle()
    elseif key == self.statsKey and isDown then
        StatUpgradeUISystem:toggle()
    elseif key == self.menuKey and isDown then
        MenuUISystem:toggle()
    elseif key == self.adminKey and isDown then
        if AdminConsoleSystem then
            AdminConsoleSystem:toggle()
        end
    elseif isDown and self.skillCastSystem then
        local idx = self.skillKeyMap[key]
        if idx then
            self.skillCastSystem:useSkill(idx)
        end
    end
end

---Performs a manual attack against the nearest enemy.
function PlayerInputSystem:manualAttack()
    local pos = self.playerPosition
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then
        return
    end
    -- Ensure the target is within attack range before applying damage
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= self.attackRange * self.attackRange then
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

