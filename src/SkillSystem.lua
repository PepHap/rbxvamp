-- SkillSystem.lua
-- Handles skills, their rarity and upgrades

local SkillSystem = {}
SkillSystem.__index = SkillSystem

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
function SkillSystem:upgradeSkill(index, amount)
    local skill = self.skills[index]
    if not skill then
        return false
    end
    if not CurrencySystem:spend("ether", amount) then
        return false
    end
    skill.level = skill.level + amount
    applySkillModule(skill)
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

return SkillSystem

