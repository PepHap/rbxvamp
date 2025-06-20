-- SkillCastSystem.lua
-- Manages casting of acquired skills with cooldowns and mana.

local RunService = game:GetService("RunService")
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

local function playRareEffect(skill)
    if skill.rarity == "S" or skill.rarity == "SS" or skill.rarity == "SSS" then
        SkillCastSystem.lastEffect = "rare"
    end
end

local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))

---Initializes the cast system with a skill system instance.
-- @param skillSys table optional SkillSystem instance
function SkillCastSystem:start(skillSys)
    self.skillSystem = skillSys or self.skillSystem or SkillSystem.new()
    local Stats = require(script.Parent:WaitForChild("StatUpgradeSystem"))
    local manaStat = Stats.stats and Stats.stats.MaxMana
    if manaStat then
        self.maxMana = (manaStat.base or 0) * (manaStat.level or 1)
    end
    local regenStat = Stats.stats and Stats.stats.ManaRegen
    if regenStat then
        self.regenRate = (regenStat.base or 0) * (regenStat.level or 1)
    end
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
    if RunService:IsClient() then
        return
    end
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
    if RunService:IsClient() then
        return false
    end
    local skill = self.skillSystem and self.skillSystem.skills[index]
    if not skill or not self:canUseSkill(index) then
        return false
    end
    local cost = (skill.level or 1) * 10
    if self.mana < cost then
        return false
    end
    self.mana = self.mana - cost
    local baseCooldown = skill.cooldown or 5
    self.cooldowns[index] = baseCooldown
    playRareEffect(skill)
    target = target or EnemySystem:getNearestEnemy({x = 0, y = 0})
    local damage = (skill.damage or 0) * (skill.level or 1)
    local mod
    if skill.module then
        local ok, m = pcall(require, "src.skills." .. skill.module)
        if ok then mod = m end
    end
    local shots = 1 + (skill.extraProjectiles or 0)
    for _ = 1, shots do
        if mod and type(mod.cast) == "function" then
            mod.cast(self.caster, skill, target)
        end
    end

    if target and target.health then
        target.health = target.health - damage
        if target.health <= 0 then
            for i, e in ipairs(EnemySystem.enemies) do
                if e == target then
                    table.remove(EnemySystem.enemies, i)
                    NetworkSystem:fireAllClients("EnemyRemove", target.name)
                    break
                end
            end
            LevelSystem:addKill()
            DungeonSystem:onEnemyKilled(target)
            EventManager:Get("EnemyDefeated"):Fire(target)
        end
        return true
    end
    return false
end

return SkillCastSystem


