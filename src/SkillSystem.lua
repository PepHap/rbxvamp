-- SkillSystem.lua
-- Handles skills, their rarity and upgrades

local SkillSystem = {}
SkillSystem.__index = SkillSystem

-- Mapping from rarity key to upgrade success chance
SkillSystem.rarityChances = {
    C = 0.05,
    D = 0.10,
    B = 0.15,
    A = 0.30,
    S = 0.50,
    SS = 0.80,
    SSS = 1.0,
}

-- Failure chance tiers based on target level
SkillSystem.failureByLevel = {
    {1, 3, 0.001},   -- 0.1% for levels 1-3
    {4, 6, 0.05},    -- 5% for levels 4-6
    {7, 9, 0.25},    -- 25% for levels 7-9
    {10, 12, 0.50},  -- 50% for levels 10-12
    {13, 15, 0.80},  -- 80% for levels 13-15
}

-- Quality ranges applied on successful upgrade. Values are percentage bonuses.
SkillSystem.qualityRanges = {
    {0.005, 0.02},   -- normal
    {0.02, 0.05},    -- good
    {0.05, 0.10},    -- great
    {0.10, 0.20},    -- perfect
    {0.20, 1.00},    -- divine
}

-- Random function used for upgrade rolls (overridable for tests)
SkillSystem.rand = math.random

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")

-- Table of predefined skills available to the game. Each skill entry
-- specifies its rarity and any additional parameters.
SkillSystem.templates = require(assets:WaitForChild("skills"))

---Creates a new skill system instance.
-- @return table
function SkillSystem.new()
    return setmetatable({skills = {}}, SkillSystem)
end

---Adds a skill to the internal list. The skill table should contain
--  ``name`` and ``rarity`` fields. The ``level`` field defaults to ``1``
--  when omitted.
-- @param skill table
local function applySkillModule(skill)
    if skill.module then
        local ok, mod = pcall(require, "src.skills." .. skill.module)
        if ok and mod and type(mod.applyLevel) == "function" then
            mod.applyLevel(skill)
        end
    end
end

function SkillSystem:addSkill(skill)
    skill.level = skill.level or 1
    table.insert(self.skills, skill)
    applySkillModule(skill)
end


---Upgrades a skill's internal level by spending Ether.
-- @param index number index of the skill in the list
-- @param amount number amount of levels to add
-- @return boolean ``true`` when the upgrade succeeds
local function failureChanceForLevel(targetLevel)
    for _, info in ipairs(SkillSystem.failureByLevel) do
        local min, max, chance = info[1], info[2], info[3]
        if targetLevel >= min and targetLevel <= max then
            return chance
        end
    end
    return 0
end

---Attempts to upgrade a skill. Each level is rolled separately using the
-- rarity and failure chance tables. Currency equal to ``amount`` ether is
-- consumed up front. Returns ``true`` only if all requested levels succeed.
function SkillSystem:upgradeSkill(index, amount)
    local skill = self.skills[index]
    if not skill then
        return false
    end
    if not CurrencySystem:spend("ether", amount) then
        return false
    end

    local successChance = SkillSystem.rarityChances[skill.rarity] or 1
    for i = 1, amount do
        local targetLevel = skill.level + 1
        local failChance = failureChanceForLevel(targetLevel)
        local roll = SkillSystem.rand()
        if roll <= successChance * (1 - failChance) then
            skill.level = targetLevel
            local qIdx = math.floor(SkillSystem.rand() * #SkillSystem.qualityRanges) + 1
            local range = SkillSystem.qualityRanges[qIdx]
            local bonus = range[1] + SkillSystem.rand() * (range[2] - range[1])
            skill.bonusPercent = (skill.bonusPercent or 0) + bonus
            applySkillModule(skill)
        else
            return false
        end
    end
    return true
end

-- Maintain the old upgrade method for compatibility with tests that may
-- call ``upgrade`` directly on a skill object.
function SkillSystem:upgrade(index, amount)
    local skill = self.skills[index]
    if skill and type(skill.upgrade) == "function" then
        skill:upgrade(amount)
    end
end

---Serializes the current list of skills into a plain table.
-- @return table serialized skill list
function SkillSystem:saveData()
    local out = {}
    for i, s in ipairs(self.skills) do
        out[i] = {
            name = s.name,
            rarity = s.rarity,
            level = s.level,
            bonusPercent = s.bonusPercent,
            module = s.module,
        }
    end
    return out
end

---Restores skills from serialized data.
-- @param data table list previously produced by ``saveData``
function SkillSystem:loadData(data)
    self.skills = {}
    if type(data) ~= "table" then
        return
    end
    for _, s in ipairs(data) do
        local skill = {
            name = s.name,
            rarity = s.rarity,
            level = s.level or 1,
            bonusPercent = s.bonusPercent,
            module = s.module,
        }
        table.insert(self.skills, skill)
        applySkillModule(skill)
    end
end

return SkillSystem

