local AutoSkillSystem = require("src.AutoSkillSystem")
local SkillCastSystem = require("src.SkillCastSystem")
local EnemySystem = require("src.EnemySystem")
local AutoBattleSystem = require("src.AutoBattleSystem")

describe("AutoSkillSystem", function()
    before_each(function()
        AutoSkillSystem.enabled = false
        AutoSkillSystem.lastSkillUsed = nil
        AutoSkillSystem.skillCastSystem = SkillCastSystem
        SkillCastSystem.skillSystem = {skills = {{name="Fireball"}}}
        SkillCastSystem.cooldowns = {0}
        EnemySystem.enemies = {{position = {x=0, y=0}, health = 1}}
        AutoBattleSystem.playerPosition = {x=0,y=0}
    end)

    it("can be enabled and disabled", function()
        AutoSkillSystem:enable()
        assert.is_true(AutoSkillSystem.enabled)
        AutoSkillSystem:disable()
        assert.is_false(AutoSkillSystem.enabled)
    end)

    it("casts a skill when enabled", function()
        function SkillCastSystem:canUseSkill(i) return true end
        function SkillCastSystem:useSkill(i)
            SkillCastSystem.used = i
            return true
        end
        AutoSkillSystem:enable()
        AutoSkillSystem:update(0)
        assert.equals(1, SkillCastSystem.used)
        assert.equals(1, AutoSkillSystem.lastSkillUsed)
    end)
end)
