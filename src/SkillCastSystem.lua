-- SkillCastSystem.lua
-- Manages casting of acquired skills with cooldowns and mana.

local SkillCastSystem = {
    ---Maximum mana available to the player.
    maxMana = 100,
    ---Current mana value regenerated over time.
    mana = 100,
    ---Mana regenerated per second.
    regenRate = 5,
    ---Table tracking remaining cooldown for each skill index.
    cooldowns = {},
    ---Reference to the active SkillSystem instance.
    skillSystem = nil,
}

local EnemySystem = require("src.EnemySystem")
local LevelSystem = require("src.LevelSystem")
local LootSystem = require("src.LootSystem")
local DungeonSystem = require("src.DungeonSystem")
local SkillSystem = require("src.SkillSystem")

---Initializes the cast system with a skill system instance.
-- @param skillSys table optional SkillSystem instance
function SkillCastSystem:start(skillSys)
    self.skillSystem = skillSys or self.skillSystem or SkillSystem.new()
    self.mana = self.maxMana
    self.cooldowns = {}
    for _ in ipairs(self.skillSystem.skills) do
        table.insert(self.cooldowns, 0)
    end
end

---Adds a new skill and prepares its cooldown entry.
-- @param skill table skill data
function SkillCastSystem:addSkill(skill)
    if not self.skillSystem then
        self.skillSystem = SkillSystem.new()
    end
    self.skillSystem:addSkill(skill)
    table.insert(self.cooldowns, 0)
end

---Regenerates mana and decreases active cooldown timers.
-- @param dt number delta time since last update
function SkillCastSystem:update(dt)
    for i = 1, #self.cooldowns do
        if self.cooldowns[i] > 0 then
            self.cooldowns[i] = math.max(0, self.cooldowns[i] - dt)
        end
    end
    self.mana = math.min(self.maxMana, self.mana + self.regenRate * dt)
end

---Returns ``true`` if the skill is ready to be cast.
-- @param index number skill index
function SkillCastSystem:canUseSkill(index)
    return self.cooldowns[index] <= 0 and self.skillSystem and self.skillSystem.skills[index] ~= nil
end

---Casts the specified skill on a target enemy if possible.
--  When no target is provided the nearest enemy is selected.
-- @param index number skill index
-- @param target table|nil enemy table
-- @return boolean ``true`` when the skill successfully cast
function SkillCastSystem:useSkill(index, target)
    local skill = self.skillSystem and self.skillSystem.skills[index]
    if not skill or not self:canUseSkill(index) then
        return false
    end
    local cost = (skill.level or 1) * 10
    if self.mana < cost then
        return false
    end
    self.mana = self.mana - cost
    self.cooldowns[index] = 5
    target = target or EnemySystem:getNearestEnemy({x = 0, y = 0})
    if target and target.health then
        target.health = target.health - (skill.damage or 0) * (skill.level or 1)
        if target.health <= 0 then
            for i, e in ipairs(EnemySystem.enemies) do
                if e == target then
                    table.remove(EnemySystem.enemies, i)
                    break
                end
            end
            LevelSystem:addKill()
            DungeonSystem:onEnemyKilled(target)
            LootSystem:onEnemyKilled(target)
        end
        return true
    end
    return false
end

return SkillCastSystem

