-- GachaSystem.lua
-- Provides weighted random rewards using tickets or crystals

local GachaSystem = {}

-- Default rarity weight tables used for all reward categories. Each entry is
-- a list of tuples ``{rarity, weight}`` where the weight acts as a relative
-- probability.  The values intentionally do not sum to 100 so additional
-- rarities can be inserted without recalculating the entire table.
-- The drop probabilities roughly match the design notes. The values are
-- normalized so the total weight equals ``100`` which keeps math simple
-- when customizing the tables. Rarer ranks use fractional percentages.
local defaultWeights = {
    -- Probabilities roughly mirror the desired design where
    -- common ranks appear most often and SSS items are nearly impossible.
    -- The weights intentionally do not sum to 100 so additional ranks can
    -- be added without recalculating all values.
    skill = {
        {"C", 80},
        {"D", 25},
        {"B", 5},
        {"A", 1},
        {"S", 0.1},
        {"SS", 0.001},
        {"SSS", 1e-12},
    },
    companion = {
        {"C", 80},
        {"D", 25},
        {"B", 5},
        {"A", 1},
        {"S", 0.1},
        {"SS", 0.001},
        {"SSS", 1e-12},
    },
    equipment = {
        {"C", 80},
        {"D", 25},
        {"B", 5},
        {"A", 1},
        {"S", 0.1},
        {"SS", 0.001},
        {"SSS", 1e-12},
    }
}

-- Active weight configuration.  This table can be changed at runtime via
-- ``setRarityWeights`` to alter drop chances per category.
GachaSystem.rarityWeights = {
    skill = defaultWeights.skill,
    companion = defaultWeights.companion,
    equipment = defaultWeights.equipment,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local skillPool = require(assets:WaitForChild("skills"))
local itemPool = require(assets:WaitForChild("items"))
local companionPool = require(assets:WaitForChild("companions"))
local EquipmentGenerator = require(script.Parent:WaitForChild("EquipmentGenerator"))
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local RunService = game:GetService("RunService")
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local LoggingSystem
if RunService and RunService.IsServer and RunService:IsServer() then
    LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))
end

-- Simple currency storage
GachaSystem.tickets = {skill = 0, companion = 0, equipment = 0}
GachaSystem.crystals = 0
---Optional inventory module for automatically storing rolled items
GachaSystem.inventory = nil

-- @param category string reward category
-- @return table weight list
function GachaSystem:getRarityWeights(category)
    return self.rarityWeights[category]
end

---Serializes tickets and crystal counts.
-- @return table data table
function GachaSystem:saveData()
    return {
        crystals = self.crystals,
        tickets = {
            skill = self.tickets.skill or 0,
            companion = self.tickets.companion or 0,
            equipment = self.tickets.equipment or 0,
        }
    }
end

---Restores ticket and crystal counts from data.
-- @param data table serialized state
function GachaSystem:loadData(data)
    if type(data) ~= "table" then return end
    self.crystals = tonumber(data.crystals) or 0
    self.tickets.skill = data.tickets and data.tickets.skill or 0
    self.tickets.companion = data.tickets and data.tickets.companion or 0
    self.tickets.equipment = data.tickets and data.tickets.equipment or 0
end

-- Returns rarity weight entries the player is allowed to roll based on level.
local function getAvailableWeights(category)
    local weights = GachaSystem.rarityWeights[category] or defaultWeights.skill
    local level = PlayerLevelSystem.level or 1
    local filter
    if category == "skill" then
        filter = function(r) return SkillSystem:isRarityUnlocked(r, level) end
    elseif category == "companion" then
        filter = function(r) return CompanionSystem:isRarityUnlocked(r, level) end
    end
    if not filter then return weights end
    local out = {}
    for _, entry in ipairs(weights) do
        if filter(entry[1]) then
            table.insert(out, entry)
        end
    end
    if #out == 0 then
        return weights
    end
    return out
end

---Selects a rarity based on the configured weights.
-- @return string rarity key
---Selects a rarity based on the configured weights for ``category``.
-- When ``category`` is omitted, ``"skill"`` weights are used.
-- @param category string|nil reward category
-- @return string rarity key
function GachaSystem:rollRarity(category)
    category = category or "skill"
    local weights = getAvailableWeights(category)
    local total = 0
    for _, entry in ipairs(weights) do
        total = total + entry[2]
    end
    local r = math.random() * total
    local acc = 0
    for _, entry in ipairs(weights) do
        acc = acc + entry[2]
        if r <= acc then
            return entry[1]
        end
    end
    return "C" -- Fallback
end

local function selectByRarity(pool, rarity)
    local matches = {}
    for _, entry in ipairs(pool) do
        if entry.rarity == rarity then
            table.insert(matches, entry)
        end
    end
    if #matches == 0 then
        matches = pool
    end
    return matches[math.random(#matches)]
end

local function consumeCurrency(self, field)
    if self.tickets[field] and self.tickets[field] > 0 then
        self.tickets[field] = self.tickets[field] - 1
        return true
    elseif self.crystals > 0 then
        self.crystals = self.crystals - 1
        return true
    end
    return false
end

return GachaSystem
