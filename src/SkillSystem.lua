-- SkillSystem.lua
-- Handles skills, their rarity and upgrades

local SkillSystem = {}
SkillSystem.__index = SkillSystem

---Creates a new skill system instance.
-- @return table
function SkillSystem.new()
    return setmetatable({skills = {}}, SkillSystem)
end

function SkillSystem:addSkill(skill)
    table.insert(self.skills, skill)
end

---Upgrades a skill if it provides an upgrade method.
-- @param index number Index of the skill to upgrade
-- @param amount number Amount of upgrade levels
function SkillSystem:upgrade(index, amount)
    local skill = self.skills[index]
    if skill and type(skill.upgrade) == "function" then
        skill:upgrade(amount)
    end
end

return SkillSystem
