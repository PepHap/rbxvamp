-- SkillSystem.lua
-- Handles skills, their rarity and upgrades

local SkillSystem = {}

SkillSystem.skills = {}

function SkillSystem:addSkill(skill)
    table.insert(self.skills, skill)
end

function SkillSystem:upgrade(skill, amount)
    -- TODO: improve skill with currency
end

return SkillSystem
