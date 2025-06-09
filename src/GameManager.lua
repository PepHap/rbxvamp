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
local EnemySystem = require("src.EnemySystem")
GameManager:addSystem("Enemy", EnemySystem)

-- Auto battle functionality can optionally control the player's actions
local AutoBattleSystem = require("src.AutoBattleSystem")
GameManager:addSystem("AutoBattle", AutoBattleSystem)


-- Player progression handling
local PlayerLevelSystem = require("src.PlayerLevelSystem")
GameManager:addSystem("PlayerLevel", PlayerLevelSystem)

-- Gacha system used for rolling random rewards
local GachaSystem = require("src.GachaSystem")
GameManager:addSystem("Gacha", GachaSystem)

-- Gauge based reward choices independent of stage/XP
local RewardGaugeSystem = require("src.RewardGaugeSystem")
GameManager:addSystem("RewardGauge", RewardGaugeSystem)

-- Quests provide structured objectives and rewards
local QuestSystem = require("src.QuestSystem")
GameManager:addSystem("Quest", QuestSystem)

-- Base stats like attack and defense upgrades
local StatUpgradeSystem = require("src.StatUpgradeSystem")
GameManager:addSystem("Stats", StatUpgradeSystem)

---Triggers a skill gacha roll.
function GameManager:rollSkill()
    return GachaSystem:rollSkill()
end

---Triggers a companion gacha roll.
function GameManager:rollCompanion()
    return GachaSystem:rollCompanion()
end

---Triggers an equipment gacha roll for the given slot.
-- @param slot string equipment slot
function GameManager:rollEquipment(slot)
    return GachaSystem:rollEquipment(slot)
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


return GameManager
