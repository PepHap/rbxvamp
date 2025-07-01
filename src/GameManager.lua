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
    assert(system ~= nil, string.format("System table must be provided for '%s'", name))
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

    -- Bind server-only remote events after all systems are ready
    if IS_SERVER and self.networkSystem and self.networkSystem.onServerEvent then
        self.networkSystem:onServerEvent("SalvageRequest", function(player, kind, arg)
            local result = false
            if kind == "inventory" then
                local index = tonumber(arg)
                if index then
                    result = self:salvageInventoryItem(index)
                end
            elseif kind == "equipped" then
                if type(arg) == "string" then
                    result = self:salvageEquippedItem(arg)
                end
            end
            self.networkSystem:fireClient(player, "SalvageResult", result)
        end)

        self.networkSystem:onServerEvent("UnequipRequest", function(player, slot)
            local removed
            if self.inventory and self.inventory.UnequipToInventory then
                removed = self.inventory:UnequipToInventory(slot)
            elseif self.itemSystem and self.itemSystem.unequipToInventory then
                removed = self.itemSystem:unequipToInventory(slot)
            end
            self.networkSystem:fireClient(player, "ItemUnequipped", removed, slot)
        end)

        self.networkSystem:onServerEvent("RewardChoice", function(player, index)
            local idx = tonumber(index)
            local choice
            if idx then
                choice = GameManager:chooseReward(idx)
            end
            if choice then
                self.networkSystem:fireClient(player, "RewardResult", choice.slot, choice.item.name)
            else
                self.networkSystem:fireClient(player, "RewardResult")
            end
        end)

        self.networkSystem:onServerEvent("RewardReroll", function(player)
            local opts = GameManager:rerollRewardOptions()
            if opts then
                self.networkSystem:fireClient(player, "GaugeOptions", opts)
            end
        end)
        self.networkSystem:onServerEvent("DungeonRequest", function(player, kind)
            local ok = GameManager:startDungeon(kind)
            if ok then
                self.networkSystem:fireClient(player, "DungeonState", kind, 0, DungeonSystem.dungeons[kind] and DungeonSystem.dungeons[kind].kills or 0)
            else
                self.networkSystem:fireClient(player, "DungeonState", nil, 0, 0)
            end
        end)
        self.networkSystem:onServerEvent("QuestRequest", function(player)
            self.networkSystem:fireClient(player, "QuestData", QuestSystem:saveData())
        end)
        self.networkSystem:onServerEvent("QuestClaim", function(player, id)
            QuestSystem:claimReward(id)
        end)

        self.networkSystem:onServerEvent("GachaRequest", function(player, kind, count, slot)
            count = tonumber(count) or 1
            local rewards
            if kind == "skill" then
                rewards = GameManager:rollSkill(count)
            elseif kind == "companion" then
                rewards = GameManager:rollCompanion(count)
            elseif kind == "equipment" then
                rewards = GameManager:rollEquipment(slot, count)
            else
                rewards = {}
            end
            if not rewards or #rewards == 0 then
                self.networkSystem:fireClient(player, "GachaResult", kind)
            else
                for _, reward in ipairs(rewards) do
                    self.networkSystem:fireClient(player, "GachaResult", kind, reward)
                end
            end
        end)

        self.networkSystem:onServerEvent("ExchangeRequest", function(player, action, kind, amount, slot, currency)
            local result
            if action == "ticket" then
                result = GameManager:buyTickets(kind, tonumber(amount) or 1)
            elseif action == "currency" then
                result = GameManager:buyCurrency(kind, tonumber(amount) or 1)
            elseif action == "upgrade" then
                result = GameManager:upgradeItemWithCrystals(slot, tonumber(amount) or 1, currency)
            elseif action == "addTicket" then
                if self.networkSystem:isAdmin(player) then
                    local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
                    GachaSystem:addTickets(kind, tonumber(amount) or 0)
                    result = true
                end
            elseif action == "addCurrency" then
                if self.networkSystem:isAdmin(player) then
                    local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
                    CurrencySystem:add(kind, tonumber(amount) or 0)
                    result = true
                end
            elseif action == "addCrystals" then
                if self.networkSystem:isAdmin(player) then
                    local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
                    GachaSystem:addCrystals(tonumber(amount) or 0)
                    result = true
                end
            end
            self.networkSystem:fireClient(player, "ExchangeResult", result)
        end)

        self.networkSystem:onServerEvent("StatUpgradeRequest", function(player, stat)
            local ok = StatUpgradeSystem:upgradeStatWithFallback(stat, 1, "gold")
            local lvl = StatUpgradeSystem.stats[stat] and StatUpgradeSystem.stats[stat].level or 0
            self.networkSystem:fireClient(player, "StatUpdate", stat, lvl)
        end)
        self.networkSystem:onServerEvent("LobbyRequest", function(player, action)
            if action == "enter" then
                LobbySystem:enter(player)
            elseif action == "leave" then
                LobbySystem:leave(player)
            end
        end)
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

-- Passes admin id list to the network system so privileged actions are allowed.
-- @param ids table array of user ids
function GameManager:setAdminIds(ids)
    if self.networkSystem and self.networkSystem.setAdminIds then
        self.networkSystem:setAdminIds(ids)
    end
end

-- Integrate the default enemy system only on the server
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local EnemySystem = require(serverFolder:WaitForChild("EnemySystem"))
    GameManager:addSystem("Enemy", EnemySystem)
end

if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local AutoBattleSystem = require(serverFolder:WaitForChild("AutoBattleSystem"))
    GameManager:addSystem("AutoBattle", AutoBattleSystem)
end

-- Handle player attack requests strictly on the server
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local AttackSystem = require(serverFolder:WaitForChild("AttackSystem"))
    GameManager:addSystem("Attack", AttackSystem)
end

-- Player progression handling available on both client and server
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
GameManager:addSystem("PlayerLevel", PlayerLevelSystem)

local RunService = game:GetService("RunService")
local PlayerSystem
if RunService:IsServer() then
    PlayerSystem = require(script.Parent.Parent:WaitForChild("server"):WaitForChild("ServerPlayerSystem"))
else
    PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
end
GameManager:addSystem("Player", PlayerSystem)

-- Stage progression between floors
local LevelSystem
if IS_SERVER then
    LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
else
    LevelSystem = require(script.Parent:WaitForChild("ClientLevelSystem"))
end
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
if GachaSystem.setInventory then
    GachaSystem:setInventory(GameManager.inventory)
end
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
        local itm = clone(t.Weapon[1])
        GameManager.itemSystem:assignId(itm)
        GameManager.itemSystem:equip("Weapon", itm)
    end
    if t and t.Hat and t.Hat[1] then
        local itm = clone(t.Hat[1])
        GameManager.itemSystem:assignId(itm)
        GameManager.itemSystem:addItem(itm)
    end
    if t and t.Ring and t.Ring[1] then
        local itm = clone(t.Ring[1])
        GameManager.itemSystem:assignId(itm)
        GameManager.itemSystem:addItem(itm)
    end
end

-- Equipment set bonuses
local SetBonusSystem = require(script.Parent:WaitForChild("SetBonusSystem"))
SetBonusSystem.itemSystem = GameManager.itemSystem
GameManager.setBonusSystem = SetBonusSystem
GameManager:addSystem("SetBonuses", SetBonusSystem)

local ItemSalvageSystem
if IS_SERVER then
    ItemSalvageSystem = require(script.Parent:WaitForChild("ItemSalvageSystem"))
    GameManager.itemSalvageSystem = ItemSalvageSystem
    GameManager:addSystem("ItemSalvage", ItemSalvageSystem)
end

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
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    TeleportSystem = require(serverFolder:WaitForChild("TeleportSystem"))
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
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    PartySystem = require(serverFolder:WaitForChild("PartySystem"))
    if TeleportSystem then
        PartySystem.teleportSystem = TeleportSystem
    end
    GameManager.partySystem = PartySystem
    GameManager:addSystem("Party", PartySystem)
end

local RaidSystem
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    RaidSystem = require(serverFolder:WaitForChild("RaidSystem"))
    if PartySystem then
        RaidSystem.partySystem = PartySystem
    end
    RaidSystem.lobbyTime = 5
    GameManager.raidSystem = RaidSystem
    GameManager:addSystem("Raid", RaidSystem)
end

-- Optional dungeon runs for earning upgrade currency
local DungeonSystem
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    DungeonSystem = require(serverFolder:WaitForChild("DungeonSystem"))
    GameManager:addSystem("Dungeon", DungeonSystem)
end

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
StatUpgradeSystem:addStat("Speed", 1)
StatUpgradeSystem:addStat("AttackSpeed", 1)

-- Data persistence for saving and loading progress (server only)
local DataPersistenceSystem
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    DataPersistenceSystem = require(serverFolder:WaitForChild("DataPersistenceSystem"))
    GameManager:addSystem("Save", DataPersistenceSystem)
    GameManager.saveSystem = DataPersistenceSystem
end

-- Automatically saves player progress at intervals
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local AutoSaveSystem = require(serverFolder:WaitForChild("AutoSaveSystem"))
    GameManager.autoSaveSystem = AutoSaveSystem
    GameManager:addSystem("AutoSave", AutoSaveSystem)
end

-- Simple currency tracking
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
GameManager.currencySystem = CurrencySystem
GameManager:addSystem("Currency", CurrencySystem)

local LoggingSystem
do
    local RunService = game:GetService("RunService")
    if RunService and RunService.IsServer and RunService:IsServer() then
        local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
        LoggingSystem = require(serverFolder:WaitForChild("LoggingSystem"))
        GameManager.loggingSystem = LoggingSystem
        GameManager:addSystem("Logging", LoggingSystem)
    end
end

if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local AntiCheatSystem = require(serverFolder:WaitForChild("AntiCheatSystem"))
    GameManager:addSystem("AntiCheat", AntiCheatSystem)
end

if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local LootSystem = require(serverFolder:WaitForChild("LootSystem"))
    GameManager.lootSystem = LootSystem
    GameManager:addSystem("Loot", LootSystem)
end

-- Daily login bonuses award extra crystals
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local DailyBonusSystem = require(serverFolder:WaitForChild("DailyBonusSystem"))
    GameManager.dailyBonusSystem = DailyBonusSystem
    GameManager:addSystem("DailyBonus", DailyBonusSystem)
end


-- Exchange crystals for tickets or upgrade currency
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local CrystalExchangeSystem = require(serverFolder:WaitForChild("CrystalExchangeSystem"))
    GameManager.crystalExchangeSystem = CrystalExchangeSystem
    GameManager:addSystem("CrystalExchange", CrystalExchangeSystem)
end

-- Skill management and upgrades
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
GameManager.skillSystem = SkillSystem.new()
GameManager:addSystem("Skills", GameManager.skillSystem)

-- Skill trees for branch upgrades
local SkillTreeSystem = require(script.Parent:WaitForChild("SkillTreeSystem"))
GameManager.skillTreeSystem = SkillTreeSystem.new(GameManager.skillSystem)
GameManager:addSystem("SkillTree", GameManager.skillTreeSystem)

local SkillCastSystem
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    SkillCastSystem = require(serverFolder:WaitForChild("SkillCastSystem"))
    SkillCastSystem.skillSystem = GameManager.skillSystem
    GameManager.skillCastSystem = SkillCastSystem
    GameManager:addSystem("SkillCast", SkillCastSystem)
    AutoBattleSystem.skillCastSystem = SkillCastSystem

    local RegenSystem = require(serverFolder:WaitForChild("RegenSystem"))
    RegenSystem.playerSystem = PlayerSystem
    RegenSystem.skillCastSystem = SkillCastSystem
    RegenSystem.statSystem = StatUpgradeSystem
    GameManager:addSystem("Regen", RegenSystem)
end

-- Optional automatic skill casting
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local AutoSkillSystem = require(serverFolder:WaitForChild("AutoSkillSystem"))
    AutoSkillSystem.skillCastSystem = SkillCastSystem
    GameManager.autoSkillSystem = AutoSkillSystem
    GameManager:addSystem("AutoSkill", AutoSkillSystem)
end

-- Companion management
local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
GameManager.companionSystem = CompanionSystem
GameManager:addSystem("Companions", CompanionSystem)

-- Companions follow the player and attack nearby enemies
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local CompanionAttackSystem = require(serverFolder:WaitForChild("CompanionAttackSystem"))
    CompanionAttackSystem.companionSystem = GameManager.companionSystem
    GameManager:addSystem("CompanionAI", CompanionAttackSystem)
end

-- Social lobby for trading
local LobbySystem
if IS_SERVER then
    LobbySystem = require(script.Parent:WaitForChild("LobbySystem"))
else
    LobbySystem = require(script.Parent:WaitForChild("ClientLobbySystem"))
end
GameManager.lobbySystem = LobbySystem
GameManager:addSystem("Lobby", LobbySystem)

-- All in-game interface now uses gui.rbxmx and is loaded by ``UILoader``.

-- Manual player input when auto battle is disabled
if RunService:IsClient() then
    local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
    GameManager:addSystem("PlayerInput", PlayerInputSystem)
end

-- Visual effects during boss fights
local BossEffectSystem = require(script.Parent:WaitForChild("BossEffectSystem"))
GameManager:addSystem("BossEffects", BossEffectSystem)

-- Track progress across locations
local ProgressMapSystem = require(script.Parent:WaitForChild("ProgressMapSystem"))
GameManager.progressMapSystem = ProgressMapSystem
GameManager:addSystem("ProgressMap", ProgressMapSystem)

-- Leaderboard tracking highest cleared stages
if IS_SERVER then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    local ScoreboardSystem = require(serverFolder:WaitForChild("ScoreboardSystem"))
    GameManager.scoreboardSystem = ScoreboardSystem
    GameManager:addSystem("Scoreboard", ScoreboardSystem)
end

-- Tutorial hints no longer display; interface handled entirely via gui.rbxmx

if IS_SERVER then
    -- Server-only functionality is defined in ``ServerGameExtensions``
    -- and attached by ``ServerGameManager`` during initialization.
end

return GameManager
