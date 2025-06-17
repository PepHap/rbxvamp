-- GameManager.lua
-- Central game management module
-- Handles initialization and main game loop

--[[
    GameManager.lua
    Central management module responsible for initializing and
    updating registered game systems.

    Systems can be any table that optionally exposes ``start`` and
    ``update`` methods. Systems are stored by name for easy retrieval.
--]]

local GameManager = {
    -- Mapping of system name to implementation
    systems = {},
    -- Ordered list of system names for deterministic iteration
    order = {}
}

--- Registers a system for later initialization and updates.
-- @param name string unique key for the system
-- @param system table table implementing optional start/update methods
function GameManager:addSystem(name, system)
    assert(name ~= nil, "System name must be provided")
    assert(system ~= nil, "System table must be provided")
    self.systems[name] = system
    table.insert(self.order, name)
end

function GameManager:start()
    -- Initialize all registered systems in the order they were added
    for _, name in ipairs(self.order) do
        local system = self.systems[name]
        if type(system.start) == "function" then
            system:start()
        end
    end
end

function GameManager:update(dt)
    -- Forward the update call to every registered system
    for _, name in ipairs(self.order) do
        local system = self.systems[name]
        if type(system.update) == "function" then
            system:update(dt)
        end
    end
end

-- Integrate the default enemy system on load
local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
GameManager:addSystem("Enemy", EnemySystem)

-- Auto battle functionality can optionally control the player's actions
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
GameManager:addSystem("AutoBattle", AutoBattleSystem)


-- Player progression handling
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
GameManager:addSystem("PlayerLevel", PlayerLevelSystem)

-- Player health management
local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
GameManager:addSystem("Player", PlayerSystem)

-- Stage progression between floors
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
GameManager:addSystem("Level", LevelSystem)

-- Tracks which area the player is currently exploring
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
GameManager:addSystem("Location", LocationSystem)

-- Applies UI theme based on the current location
local ThemeSystem = require(script.Parent:WaitForChild("ThemeSystem"))
ThemeSystem.locationSystem = LocationSystem
GameManager:addSystem("Theme", ThemeSystem)

-- Gacha system used for rolling random rewards
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
GameManager:addSystem("Gacha", GachaSystem)

-- Gauge based reward choices independent of stage/XP
local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
GameManager:addSystem("RewardGauge", RewardGaugeSystem)

-- Achievement tracking for milestone rewards
local AchievementSystem = require(script.Parent:WaitForChild("AchievementSystem"))
GameManager.achievementSystem = AchievementSystem
GameManager:addSystem("Achievements", AchievementSystem)

-- Equipment handling
local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
GameManager.itemSystem = ItemSystem.new()
GameManager:addSystem("Items", GameManager.itemSystem)

-- Quests provide structured objectives and rewards
local QuestSystem = require(script.Parent:WaitForChild("QuestSystem"))
GameManager:addSystem("Quest", QuestSystem)

-- Keys used to unlock special areas and modes
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
GameManager:addSystem("Keys", KeySystem)

-- Optional dungeon runs for earning upgrade currency
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
GameManager:addSystem("Dungeon", DungeonSystem)

-- Base stats like attack and defense upgrades
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
GameManager:addSystem("Stats", StatUpgradeSystem)

-- Data persistence for saving and loading progress
local DataPersistenceSystem = require(script.Parent:WaitForChild("DataPersistenceSystem"))
GameManager:addSystem("Save", DataPersistenceSystem)
GameManager.saveSystem = DataPersistenceSystem

-- Automatically saves player progress at intervals
local AutoSaveSystem = require(script.Parent:WaitForChild("AutoSaveSystem"))
GameManager.autoSaveSystem = AutoSaveSystem
GameManager:addSystem("AutoSave", AutoSaveSystem)

-- Skill management and upgrades
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
GameManager.skillSystem = SkillSystem.new()
GameManager:addSystem("Skills", GameManager.skillSystem)

-- Skill casting using mana and cooldowns
local SkillCastSystem = require(script.Parent:WaitForChild("SkillCastSystem"))
SkillCastSystem.skillSystem = GameManager.skillSystem
GameManager.skillCastSystem = SkillCastSystem
GameManager:addSystem("SkillCast", SkillCastSystem)

-- Companion management
local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
GameManager.companionSystem = CompanionSystem
GameManager:addSystem("Companions", CompanionSystem)

-- Companions follow the player and attack nearby enemies
local CompanionAttackSystem = require(script.Parent:WaitForChild("CompanionAttackSystem"))
CompanionAttackSystem.companionSystem = GameManager.companionSystem
GameManager:addSystem("CompanionAI", CompanionAttackSystem)

-- Minimal UI for displaying rewards and gacha results
local UISystem = require(script.Parent:WaitForChild("UISystem"))
GameManager:addSystem("UI", UISystem)

-- Inventory UI provides equipment and bag management
local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
InventoryUISystem.itemSystem = GameManager.itemSystem

GameManager:addSystem("InventoryUI", InventoryUISystem)

-- Gacha UI for rolling rewards
local GachaUISystem = require(script.Parent:WaitForChild("GachaUISystem"))
GachaUISystem.gameManager = GameManager
GameManager:addSystem("GachaUI", GachaUISystem)

-- Heads-up display with level, experience and currency
local HudSystem = require(script.Parent:WaitForChild("HudSystem"))
GameManager:addSystem("HUD", HudSystem)

-- Skill and companion UI modules
local SkillUISystem = require(script.Parent:WaitForChild("SkillUISystem"))
SkillUISystem.skillSystem = GameManager.skillSystem
GameManager:addSystem("SkillUI", SkillUISystem)

local CompanionUISystem = require(script.Parent:WaitForChild("CompanionUISystem"))
CompanionUISystem.companionSystem = GameManager.companionSystem
GameManager:addSystem("CompanionUI", CompanionUISystem)

-- UI for upgrading base stats
local StatUpgradeUISystem = require(script.Parent:WaitForChild("StatUpgradeUISystem"))
StatUpgradeUISystem.statSystem = StatUpgradeSystem
GameManager:addSystem("StatUI", StatUpgradeUISystem)

-- Manual player input when auto battle is disabled
local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
GameManager:addSystem("PlayerInput", PlayerInputSystem)

---Triggers a skill gacha roll.
function GameManager:rollSkill()
    local reward = GachaSystem:rollSkill()
    if reward then
        self.skillSystem:addSkill(reward)
        if self.skillCastSystem and self.skillCastSystem.addSkill then
            self.skillCastSystem:addSkill(reward)
        end
    end
    return reward
end

---Triggers a companion gacha roll.
function GameManager:rollCompanion()
    local reward = GachaSystem:rollCompanion()
    if reward then
        self.companionSystem:add(reward)
        local ai = self.systems and self.systems.CompanionAI
        if ai and ai.addCompanion then
            ai:addCompanion(reward)
        end
    end
    return reward
end

---Triggers an equipment gacha roll for the given slot.
-- @param slot string equipment slot
function GameManager:rollEquipment(slot)
    local reward = GachaSystem:rollEquipment(slot)
    if reward then
        self.itemSystem:addItem(reward)
    end
    return reward
end

---Adds points to the reward gauge.
-- @param amount number amount to add
function GameManager:addRewardPoints(amount)
    RewardGaugeSystem:addPoints(amount)
end

---Returns reward options when the gauge is full.
function GameManager:getRewardOptions()
    return RewardGaugeSystem:getOptions()
end

---Chooses one of the reward options.
-- @param index number option index
function GameManager:chooseReward(index)
    local chosen = RewardGaugeSystem:choose(index)
    if chosen then
        self.itemSystem:equip(chosen.slot, chosen.item)
    end
    return chosen
end

---Loads persistent data for a player using the Save system.
-- @param playerId string|number player identifier
-- @return table data table
function GameManager:loadPlayerData(playerId)
    if self.saveSystem and self.saveSystem.load then
        return self.saveSystem:load(playerId)
    end
    return {}
end

---Saves persistent data for a player using the Save system.
-- @param playerId string|number player identifier
-- @param data table data table to save
function GameManager:savePlayerData(playerId, data)
    if self.saveSystem and self.saveSystem.save then
        self.saveSystem:save(playerId, data)
    end
end


return GameManager
