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
local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local skillPool = ModuleUtil.loadAssetModule("skills") or {}
local itemPool = ModuleUtil.loadAssetModule("items") or {}
local companionPool = ModuleUtil.loadAssetModule("companions") or {}
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

---Overrides the rarity weights for a specific category.
-- @param category string category name
-- @param weights table list of {rarity, weight}
function GachaSystem:setRarityWeights(category, weights)
    if type(category) ~= "string" or type(weights) ~= "table" then
        return
    end
    self.rarityWeights[category] = weights
end

---Adds crystals to the player's balance.
-- @param amount number quantity to add
function GachaSystem:addCrystals(amount)
    local n = tonumber(amount) or 0
    self.crystals = self.crystals + n
    if LoggingSystem and LoggingSystem.logCurrency then
        LoggingSystem:logCurrency(nil, "crystal", n)
    end
    if NetworkSystem and NetworkSystem.fireAllClients then
        NetworkSystem:fireAllClients("CurrencyUpdate", "crystal", self.crystals)
    end
end

---Attempts to spend crystals from the balance.
-- @param amount number amount to deduct
-- @return boolean success
function GachaSystem:spendCrystals(amount)
    local n = tonumber(amount) or 0
    if n <= 0 then
        return false
    end
    if self.crystals >= n then
        self.crystals = self.crystals - n
        if LoggingSystem and LoggingSystem.logCurrency then
            LoggingSystem:logCurrency(nil, "crystal", -n)
        end
        if NetworkSystem and NetworkSystem.fireAllClients then
            NetworkSystem:fireAllClients("CurrencyUpdate", "crystal", self.crystals)
        end
        return true
    end
    return false
end

---Adds gacha tickets of the given type.
function GachaSystem:addTickets(kind, amount)
    if self.tickets[kind] == nil then
        return
    end
    local n = tonumber(amount) or 0
    self.tickets[kind] = self.tickets[kind] + n
    if LoggingSystem and LoggingSystem.logCurrency then
        LoggingSystem:logCurrency(nil, kind .. "_ticket", n)
    end
end

---Sets an inventory module for storing rolled equipment.
function GachaSystem:setInventory(inv)
    self.inventory = inv
end

---Rolls a skill reward consuming currency when available.
function GachaSystem:rollSkill()
    if not consumeCurrency(self, "skill") then
        return nil
    end
    local rarity = self:rollRarity("skill")
    local reward = selectByRarity(skillPool, rarity)
    if reward and LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, reward, "skill")
    end
    return reward
end

---Rolls multiple skills up to ``count`` times.
function GachaSystem:rollSkills(count)
    local results = {}
    local n = tonumber(count) or 1
    for _ = 1, n do
        local reward = self:rollSkill()
        if not reward then
            break
        end
        table.insert(results, reward)
    end
    return results
end

---Rolls a companion reward.
function GachaSystem:rollCompanion()
    if not consumeCurrency(self, "companion") then
        return nil
    end
    local rarity = self:rollRarity("companion")
    local reward = selectByRarity(companionPool, rarity)
    if reward and LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, reward, "companion")
    end
    return reward
end

---Rolls multiple companions.
function GachaSystem:rollCompanions(count)
    local results = {}
    local n = tonumber(count) or 1
    for _ = 1, n do
        local reward = self:rollCompanion()
        if not reward then
            break
        end
        table.insert(results, reward)
    end
    return results
end

---Rolls an equipment item for the specified slot.
function GachaSystem:rollEquipment(slot)
    if not consumeCurrency(self, "equipment") then
        return nil
    end
    local rarity = self:rollRarity("equipment")
    local reward = EquipmentGenerator.getRandomItem(slot, rarity, itemPool)
    if not reward then
        return nil
    end
    if self.inventory and self.inventory.AddItem then
        self.inventory:AddItem(reward)
    end
    if reward and LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, reward, "equipment")
    end
    return reward
end

---Rolls multiple equipment items until currency runs out.
function GachaSystem:rollEquipmentMultiple(slot, count)
    local results = {}
    local n = tonumber(count) or 1
    for _ = 1, n do
        local reward = self:rollEquipment(slot)
        if not reward then
            break
        end
        table.insert(results, reward)
    end
    return results
end

return GachaSystem
