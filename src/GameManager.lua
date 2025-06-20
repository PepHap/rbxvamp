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

local RunService = game:GetService("RunService")
local IS_SERVER = RunService:IsServer()

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

-- Integrate the default enemy system only on the server
if IS_SERVER then
    local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
    GameManager:addSystem("Enemy", EnemySystem)
end

-- Auto battle functionality can optionally control the player's actions
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
GameManager:addSystem("AutoBattle", AutoBattleSystem)

-- Handle player attack requests strictly on the server
if IS_SERVER then
    local AttackSystem = require(script.Parent:WaitForChild("AttackSystem"))
    GameManager:addSystem("Attack", AttackSystem)
end

-- Player progression handling available on both client and server
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

-- Environment lighting adjustments per location
local LightingSystem = require(script.Parent:WaitForChild("LightingSystem"))
LightingSystem.locationSystem = LocationSystem
GameManager:addSystem("Lighting", LightingSystem)

-- Simple post processing effects for boss encounters
local PostProcessingSystem = require(script.Parent:WaitForChild("PostProcessingSystem"))
GameManager:addSystem("PostFX", PostProcessingSystem)

-- Gacha system used for rolling random rewards
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
GameManager:addSystem("Gacha", GachaSystem)

-- Gauge based reward choices independent of stage/XP
local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
GameManager:addSystem("RewardGauge", RewardGaugeSystem)
RewardGaugeSystem.onSelect = function(choice)
    if not choice then return end
    if GameManager.inventory and GameManager.inventory.EquipItem then
        GameManager.inventory:EquipItem(choice.slot, choice.item)
    else
        GameManager.itemSystem:equip(choice.slot, choice.item)
    end
end

-- Achievement tracking for milestone rewards
local AchievementSystem = require(script.Parent:WaitForChild("AchievementSystem"))
GameManager.achievementSystem = AchievementSystem
GameManager:addSystem("Achievements", AchievementSystem)

-- Equipment handling
local InventoryModule = require(script.Parent:WaitForChild("InventoryModule"))
local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
GameManager.inventory = InventoryModule.new()
GameManager.itemSystem = GameManager.inventory.itemSystem
GameManager:addSystem("Items", GameManager.itemSystem)

do
    local function clone(tbl)
        if type(tbl) ~= "table" then return tbl end
        local c = {}
        for k, v in pairs(tbl) do
            c[k] = clone(v)
        end
        return c
    end
    local t = ItemSystem.templates
    if t and t.Weapon and t.Weapon[1] then
        GameManager.itemSystem:equip("Weapon", clone(t.Weapon[1]))
    end
    if t and t.Hat and t.Hat[1] then
        GameManager.itemSystem:addItem(clone(t.Hat[1]))
    end
    if t and t.Ring and t.Ring[1] then
        GameManager.itemSystem:addItem(clone(t.Ring[1]))
    end
end

-- Equipment set bonuses
local SetBonusSystem = require(script.Parent:WaitForChild("SetBonusSystem"))
SetBonusSystem.itemSystem = GameManager.itemSystem
GameManager.setBonusSystem = SetBonusSystem
GameManager:addSystem("SetBonuses", SetBonusSystem)

-- Item salvage handling for converting equipment into currency
local ItemSalvageSystem = require(script.Parent:WaitForChild("ItemSalvageSystem"))
GameManager.itemSalvageSystem = ItemSalvageSystem
GameManager:addSystem("ItemSalvage", ItemSalvageSystem)

-- Quests provide structured objectives and rewards
local QuestSystem = require(script.Parent:WaitForChild("QuestSystem"))
GameManager:addSystem("Quest", QuestSystem)

-- Keys used to unlock special areas and modes
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
GameManager:addSystem("Keys", KeySystem)

-- Remote event networking
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
GameManager.networkSystem = NetworkSystem
GameManager:addSystem("Network", NetworkSystem)

-- Handles teleporting groups between places (server only)
local TeleportSystem
if IS_SERVER then
    TeleportSystem = require(script.Parent:WaitForChild("TeleportSystem"))
    GameManager.teleportSystem = TeleportSystem
    GameManager:addSystem("Teleport", TeleportSystem)
    TeleportSystem.raidPlaceId = 0
    TeleportSystem.lobbyPlaceId = 0
    if TeleportSystem.start then
        TeleportSystem:start()
    end
end

local PartySystem
if IS_SERVER then
    PartySystem = require(script.Parent:WaitForChild("PartySystem"))
    GameManager.partySystem = PartySystem
    GameManager:addSystem("Party", PartySystem)
end

local RaidSystem
if IS_SERVER then
    RaidSystem = require(script.Parent:WaitForChild("RaidSystem"))
    if PartySystem then
        RaidSystem.partySystem = PartySystem
    end
    GameManager.raidSystem = RaidSystem
    GameManager:addSystem("Raid", RaidSystem)
end

-- Optional dungeon runs for earning upgrade currency
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
GameManager:addSystem("Dungeon", DungeonSystem)

-- Base stats like attack and defense upgrades
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
GameManager:addSystem("Stats", StatUpgradeSystem)
GameManager.inventory.statSystem = StatUpgradeSystem
GameManager.inventory.setSystem = SetBonusSystem
-- Define some base player stats used by the inventory display
StatUpgradeSystem:addStat("Health", 100)
StatUpgradeSystem:addStat("Attack", 5)
StatUpgradeSystem:addStat("Defense", 0)
StatUpgradeSystem:addStat("Magic", 0)
StatUpgradeSystem:addStat("CritChance", 0.05)
StatUpgradeSystem:addStat("CritDamage", 1.5)
StatUpgradeSystem:addStat("HealthRegen", 1)
StatUpgradeSystem:addStat("MaxMana", 100)
StatUpgradeSystem:addStat("ManaRegen", 5)

-- Data persistence for saving and loading progress (server only)
local DataPersistenceSystem
if IS_SERVER then
    DataPersistenceSystem = require(script.Parent:WaitForChild("DataPersistenceSystem"))
    GameManager:addSystem("Save", DataPersistenceSystem)
    GameManager.saveSystem = DataPersistenceSystem
end

-- Automatically saves player progress at intervals
local AutoSaveSystem = require(script.Parent:WaitForChild("AutoSaveSystem"))
GameManager.autoSaveSystem = AutoSaveSystem
GameManager:addSystem("AutoSave", AutoSaveSystem)

-- Simple currency tracking
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
GameManager.currencySystem = CurrencySystem
GameManager:addSystem("Currency", CurrencySystem)

-- Exchange crystals for tickets or upgrade currency
local CrystalExchangeSystem = require(script.Parent:WaitForChild("CrystalExchangeSystem"))
GameManager.crystalExchangeSystem = CrystalExchangeSystem
GameManager:addSystem("CrystalExchange", CrystalExchangeSystem)

-- Skill management and upgrades
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
GameManager.skillSystem = SkillSystem.new()
GameManager:addSystem("Skills", GameManager.skillSystem)

-- Skill trees for branch upgrades
local SkillTreeSystem = require(script.Parent:WaitForChild("SkillTreeSystem"))
GameManager.skillTreeSystem = SkillTreeSystem.new(GameManager.skillSystem)
GameManager:addSystem("SkillTree", GameManager.skillTreeSystem)

-- Skill casting using mana and cooldowns
local SkillCastSystem = require(script.Parent:WaitForChild("SkillCastSystem"))
SkillCastSystem.skillSystem = GameManager.skillSystem
GameManager.skillCastSystem = SkillCastSystem
GameManager:addSystem("SkillCast", SkillCastSystem)
AutoBattleSystem.skillCastSystem = SkillCastSystem
local RegenSystem = require(script.Parent:WaitForChild("RegenSystem"))
RegenSystem.playerSystem = PlayerSystem
RegenSystem.skillCastSystem = SkillCastSystem
RegenSystem.statSystem = StatUpgradeSystem
GameManager:addSystem("Regen", RegenSystem)

-- Optional automatic skill casting
local AutoSkillSystem = require(script.Parent:WaitForChild("AutoSkillSystem"))
AutoSkillSystem.skillCastSystem = SkillCastSystem
GameManager.autoSkillSystem = AutoSkillSystem
GameManager:addSystem("AutoSkill", AutoSkillSystem)

-- Companion management
local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
GameManager.companionSystem = CompanionSystem
GameManager:addSystem("Companions", CompanionSystem)

-- Companions follow the player and attack nearby enemies
local CompanionAttackSystem = require(script.Parent:WaitForChild("CompanionAttackSystem"))
CompanionAttackSystem.companionSystem = GameManager.companionSystem
GameManager:addSystem("CompanionAI", CompanionAttackSystem)

-- Social lobby for trading
local LobbySystem = require(script.Parent:WaitForChild("LobbySystem"))
GameManager.lobbySystem = LobbySystem
GameManager:addSystem("Lobby", LobbySystem)

if RunService:IsClient() then
    -- Minimal UI for displaying rewards and gacha results
    local UISystem = require(script.Parent:WaitForChild("UISystem"))
    GameManager:addSystem("UI", UISystem)

    -- Inventory UI provides equipment and bag management
    local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
    InventoryUISystem.itemSystem = GameManager.itemSystem
    InventoryUISystem.statSystem = StatUpgradeSystem
    InventoryUISystem.setSystem = SetBonusSystem
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

    local SkillTreeUISystem = require(script.Parent:WaitForChild("SkillTreeUISystem"))
    SkillTreeUISystem.treeSystem = GameManager.skillTreeSystem
    GameManager:addSystem("SkillTreeUI", SkillTreeUISystem)

    local CompanionUISystem = require(script.Parent:WaitForChild("CompanionUISystem"))
    CompanionUISystem.companionSystem = GameManager.companionSystem
    GameManager:addSystem("CompanionUI", CompanionUISystem)

    local AchievementUISystem = require(script.Parent:WaitForChild("AchievementUISystem"))
    AchievementUISystem.achievementSystem = AchievementSystem
    GameManager:addSystem("AchievementUI", AchievementUISystem)

    -- Main menu UI providing access to inventory and skills
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    GameManager:addSystem("MenuUI", MenuUISystem)

    -- UI for upgrading base stats
    local StatUpgradeUISystem = require(script.Parent:WaitForChild("StatUpgradeUISystem"))
    StatUpgradeUISystem.statSystem = StatUpgradeSystem
    GameManager:addSystem("StatUI", StatUpgradeUISystem)

    -- UI for exchanging crystals into tickets or currency
    local CrystalExchangeUISystem = require(script.Parent:WaitForChild("CrystalExchangeUISystem"))
    CrystalExchangeUISystem.exchangeSystem = CrystalExchangeSystem
    GameManager:addSystem("CrystalExchangeUI", CrystalExchangeUISystem)

    local DungeonUISystem = require(script.Parent:WaitForChild("DungeonUISystem"))
    DungeonUISystem.dungeonSystem = DungeonSystem
    GameManager:addSystem("DungeonUI", DungeonUISystem)

    local LobbyUISystem = require(script.Parent:WaitForChild("LobbyUISystem"))
    LobbyUISystem.lobbySystem = LobbySystem
    GameManager:addSystem("LobbyUI", LobbyUISystem)

    local PartyUISystem = require(script.Parent:WaitForChild("PartyUISystem"))
    GameManager:addSystem("PartyUI", PartyUISystem)

    local RaidUISystem = require(script.Parent:WaitForChild("RaidUISystem"))
    GameManager:addSystem("RaidUI", RaidUISystem)

    -- Admin console for privileged commands
    local adminModule
    local ok, result = pcall(function()
        return require(script.Parent:WaitForChild("AdminConsoleSystem"))
    end)
    if ok then
        adminModule = result
    end
    if adminModule then
        adminModule.gameManager = GameManager
        GameManager:addSystem("AdminConsole", adminModule)
    end
end

-- Manual player input when auto battle is disabled
local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
GameManager:addSystem("PlayerInput", PlayerInputSystem)

-- Visual effects during boss fights
local BossEffectSystem = require(script.Parent:WaitForChild("BossEffectSystem"))
GameManager:addSystem("BossEffects", BossEffectSystem)

-- Track progress across locations
local ProgressMapSystem = require(script.Parent:WaitForChild("ProgressMapSystem"))
GameManager.progressMapSystem = ProgressMapSystem
GameManager:addSystem("ProgressMap", ProgressMapSystem)

-- Simple map UI
local ProgressMapUISystem = require(script.Parent:WaitForChild("ProgressMapUISystem"))
ProgressMapUISystem.progressSystem = ProgressMapSystem
if RunService:IsClient() then
    GameManager:addSystem("ProgressMapUI", ProgressMapUISystem)
end

-- Tutorial hints
local TutorialSystem = require(script.Parent:WaitForChild("TutorialSystem"))
GameManager:addSystem("Tutorial", TutorialSystem)

---Triggers a skill gacha roll.
function GameManager:rollSkill()
    if not PlayerLevelSystem:isUnlocked("skills") then
        return nil
    end
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
    if not PlayerLevelSystem:isUnlocked("companions") then
        return nil
    end
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
        if self.inventory and self.inventory.AddItem then
            self.inventory:AddItem(reward)
        else
            self.itemSystem:addItem(reward)
        end
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
    return RewardGaugeSystem:choose(index)
end

---Resets the reward gauge completely.
function GameManager:resetRewardGauge()
    if RewardGaugeSystem.resetGauge then
        RewardGaugeSystem:resetGauge()
    end
end

---Purchases gacha tickets using the crystal exchange system.
-- @param kind string ticket type
-- @param amount number number of tickets
-- @return boolean success
function GameManager:buyTickets(kind, amount)
    if self.crystalExchangeSystem and self.crystalExchangeSystem.buyTickets then
        return self.crystalExchangeSystem:buyTickets(kind, amount)
    end
    return false
end

---Purchases upgrade currency using crystals through the exchange system.
-- @param kind string currency type
-- @param amount number quantity to buy
-- @return boolean success
function GameManager:buyCurrency(kind, amount)
    if self.crystalExchangeSystem and self.crystalExchangeSystem.buyCurrency then
        return self.crystalExchangeSystem:buyCurrency(kind, amount)
    end
    return false
end

---Upgrades an equipped item by spending crystals instead of currency.
-- @param slot string equipment slot name
-- @param amount number levels to upgrade
-- @param currencyType string currency used for pricing
-- @return boolean success
function GameManager:upgradeItemWithCrystals(slot, amount, currencyType)
    if not self.crystalExchangeSystem then
        return false
    end
    -- Prefer a directly assigned item system instance when available.
    -- Fall back to the one provided by the inventory module.
    local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
    return self.crystalExchangeSystem:upgradeItemWithCrystals(itemSys, slot, amount, currencyType)
end


---Collects save data from major systems for persistence.
-- @return table aggregated data table
function GameManager:getSaveData()
    return {
        currency = CurrencySystem:saveData(),
        gacha = GachaSystem:saveData(),
        items = self.itemSystem:toData(),
        playerLevel = PlayerLevelSystem:saveData(),
        levelState = LevelSystem:saveData(),
        keys = KeySystem:saveData(),
        rewardGauge = RewardGaugeSystem:saveData(),
        skills = self.skillSystem:saveData(),
        companions = self.companionSystem:saveData(),
        stats = StatUpgradeSystem:saveData(),
        achievements = AchievementSystem:saveData(),
    }
end

---Applies saved data to restore player state.
-- @param data table aggregated save data
function GameManager:applySaveData(data)
    if type(data) ~= "table" then return end
    CurrencySystem:loadData(data.currency)
    GachaSystem:loadData(data.gacha)
    local newItems = ItemSystem.fromData(data.items or {})
    self.itemSystem = newItems
    if self.inventory then
        self.inventory.itemSystem = newItems
    end
    if self.setBonusSystem then
        self.setBonusSystem.itemSystem = newItems
    end
    self.skillSystem:loadData(data.skills)
    self.companionSystem:loadData(data.companions)
    StatUpgradeSystem:loadData(data.stats)
    PlayerLevelSystem:loadData(data.playerLevel)
    LevelSystem:loadData(data.levelState)
    KeySystem:loadData(data.keys)
    RewardGaugeSystem:loadData(data.rewardGauge)
    AchievementSystem:loadData(data.achievements)
end

---Salvages an item from the inventory into currency and crystals.
-- @param index number inventory index
-- @return boolean success
function GameManager:salvageInventoryItem(index)
    local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
    if not self.itemSalvageSystem or not itemSys then
        return false
    end
    return self.itemSalvageSystem:salvageFromInventory(itemSys, index)
end

---Salvages an equipped item from the given slot.
-- @param slot string equipment slot name
-- @return boolean success
function GameManager:salvageEquippedItem(slot)
    local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
    if not self.itemSalvageSystem or not itemSys then
        return false
    end
    local itm = itemSys:unequip(slot)
    if not itm then
        return false
    end
    return self.itemSalvageSystem:salvageItem(itm)
end

---Creates a new party lead by the given player reference.
function GameManager:createParty(player)
    if self.partySystem and self.partySystem.createParty then
        return self.partySystem:createParty(player)
    end
    return nil
end

---Adds the player to an existing party.
function GameManager:joinParty(id, player)
    if self.partySystem and self.partySystem.addMember then
        return self.partySystem:addMember(id, player)
    end
    return false
end

---Removes the player from a party.
function GameManager:leaveParty(id, player)
    if self.partySystem and self.partySystem.removeMember then
        return self.partySystem:removeMember(id, player)
    end
    return false
end

---Begins a raid encounter for the current party.
function GameManager:startRaid(player)
    if self.raidSystem and self.raidSystem.startRaid then
        return self.raidSystem:startRaid(player)
    end
    return false
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
