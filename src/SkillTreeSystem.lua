-- SkillTreeSystem.lua
-- Handles branch selection and branch-based upgrades for skills

local SkillTreeSystem = {}
SkillTreeSystem.__index = SkillTreeSystem

local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local treeConfig = require(assets:WaitForChild("skill_trees"))

---Creates a new SkillTreeSystem
---@param skillSystem table existing SkillSystem instance
function SkillTreeSystem.new(skillSystem)
    local self = setmetatable({}, SkillTreeSystem)
    self.skillSystem = skillSystem or SkillSystem.new()
    self.config = treeConfig
    return self
end

local function applyBranch(skill, branches)
    if not skill.branch then return end
    local cfg
    for _, b in ipairs(branches or {}) do
        if b.id == skill.branch then
            cfg = b
            break
        end
    end
    if not cfg or not cfg.steps then return end
    for _, step in ipairs(cfg.steps) do
        if skill.level >= step.level then
            for prop, val in pairs(step.changes or {}) do
                skill[prop] = (skill[prop] or 0) + val
            end
        end
    end
end

---Selects a branch for the given skill index
function SkillTreeSystem:chooseBranch(index, branchId)
    local skill = self.skillSystem.skills[index]
    if not skill or skill.branch then
        return false
    end
    skill.branch = branchId
    applyBranch(skill, treeConfig[skill.name])
    return true
end

---Upgrades a skill using SkillSystem then applies branch bonuses
function SkillTreeSystem:upgradeSkill(index, amount)
    local ok = self.skillSystem:upgradeSkill(index, amount)
    if ok then
        local skill = self.skillSystem.skills[index]
        applyBranch(skill, treeConfig[skill.name])
    end
    return ok
end

return SkillTreeSystem
