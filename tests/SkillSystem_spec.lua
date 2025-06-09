local SkillSystem = require("../src/SkillSystem")

describe("SkillSystem", function()
    it("can add a skill", function()
        SkillSystem.skills = {}
        SkillSystem:addSkill("Fireball")
        assert.are.same({"Fireball"}, SkillSystem.skills)
    end)
end)
