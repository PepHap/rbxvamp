-- AutoSkillSystem.lua
-- Automatically casts skills using SkillCastSystem when enabled

local AutoSkillSystem = {
    enabled = false,
    skillCastSystem = nil,
    lastSkillUsed = nil,
}

local EnemySystem = require(script.Parent:WaitForChild("EnemySystem"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local SkillCastSystem = require(script.Parent:WaitForChild("SkillCastSystem"))

---Initializes the system with a SkillCastSystem instance.
-- @param castSys table optional SkillCastSystem instance
function AutoSkillSystem:start(castSys)
    self.skillCastSystem = castSys or self.skillCastSystem or SkillCastSystem
end

function AutoSkillSystem:enable()
    self.enabled = true
end

function AutoSkillSystem:disable()
    self.enabled = false
end

---Automatically casts available skills on the nearest enemy when enabled.
-- @param dt number delta time
function AutoSkillSystem:update(dt)
    if not self.enabled or not self.skillCastSystem then
        return
    end

    local skills = self.skillCastSystem.skillSystem and self.skillCastSystem.skillSystem.skills or {}
    for i = 1, math.min(4, #skills) do
        if self.skillCastSystem:canUseSkill(i) then
            local pos = AutoBattleSystem.playerPosition or {x = 0, y = 0}
            local target = EnemySystem:getNearestEnemy(pos)
            if target and self.skillCastSystem:useSkill(i, target) then
                self.lastSkillUsed = i
                break
            end
        end
    end
end

return AutoSkillSystem
