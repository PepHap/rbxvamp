-- GachaSystem.lua
-- Provides weighted random rewards using tickets or crystals

local GachaSystem = {}

-- Rarity weights used when rolling. Values do not need to sum to 100 and
-- are treated as relative chances.
GachaSystem.rarityWeights = {
    {"C", 80},
    {"D", 25},
    {"B", 5},
    {"A", 1},
    {"S", 0.1},
    {"SS", 0.001},
    {"SSS", 1e-12},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local skillPool = require(assets:WaitForChild("skills"))
local itemPool = require(assets:WaitForChild("items"))
local companionPool = require(assets:WaitForChild("companions"))

-- Simple currency storage
GachaSystem.tickets = {skill = 0, companion = 0, equipment = 0}
GachaSystem.crystals = 0

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

---Selects a rarity based on the configured weights.
-- @return string rarity key
function GachaSystem:rollRarity()
    local total = 0
    for _, entry in ipairs(self.rarityWeights) do
        total = total + entry[2]
    end
    local r = math.random() * total
    local acc = 0
    for _, entry in ipairs(self.rarityWeights) do
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

---Rolls a skill reward using available currency.
-- @return table|nil selected skill
function GachaSystem:rollSkill()
    if not consumeCurrency(self, "skill") then
        return nil
    end
    local rarity = self:rollRarity()
    return selectByRarity(skillPool, rarity)
end

---Rolls a companion reward using available currency.
-- @return table|nil selected companion
function GachaSystem:rollCompanion()
    if not consumeCurrency(self, "companion") then
        return nil
    end
    local rarity = self:rollRarity()
    return selectByRarity(companionPool, rarity)
end

---Rolls an equipment reward for the given slot.
-- @param slot string item slot name
-- @return table|nil selected item
function GachaSystem:rollEquipment(slot)
    if not consumeCurrency(self, "equipment") then
        return nil
    end
    local pool = itemPool[slot]
    if not pool then
        return nil
    end
    local rarity = self:rollRarity()
    return selectByRarity(pool, rarity)
end

return GachaSystem
