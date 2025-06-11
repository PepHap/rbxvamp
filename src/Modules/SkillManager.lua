local Roulette = require(script.Parent.Roulette)

local SkillManager = {}
SkillManager.__index = SkillManager

local skillsByRarity = {
    SSS = {"Time Stop"},
    SS = {"Dragon Fury"},
    S = {"Meteor Strike"},
    A = {"Lightning Bolt"},
    B = {"Fireball", "Ice Spike"},
    C = {"Magic Missile", "Minor Heal"},
    D = {"Punch"},
}

function SkillManager.new(playerManager)
    local self = setmetatable({}, SkillManager)
    self.PlayerManager = playerManager
    self.Skills = {}
    return self
end

function SkillManager:RollSkill()
    if not self.PlayerManager:SpendCurrency("Tickets", 1) then
        return nil
    end
    local skill, rarity = Roulette:GetRandomItem(skillsByRarity)
    if skill then
        table.insert(self.Skills, {Name = skill, Rarity = rarity, Level = 1})
    end
    return skill, rarity
end

function SkillManager:UpgradeSkill(skillName, cost)
    if not self.PlayerManager:SpendCurrency("Ether", cost) then
        return false
    end
    for _, skill in ipairs(self.Skills) do
        if skill.Name == skillName then
            skill.Level += 1
            return true
        end
    end
    return false
end

return SkillManager
