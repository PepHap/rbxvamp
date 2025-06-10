local SkillSystem = require("src.SkillSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("SkillSystem", function()
    it("can add a skill", function()
        SkillSystem.skills = {}
        SkillSystem:addSkill({name = "Fireball", rarity = "A"})
        local skill = SkillSystem.skills[1]
        assert.equals("Fireball", skill.name)
        assert.equals("A", skill.rarity)
        assert.equals(1, skill.level)
    end)

    it("upgrades a skill when enough currency", function()
        SkillSystem.skills = {}
        CurrencySystem.balances = {ether = 5}
        SkillSystem:addSkill({name = "Spark", rarity = "C"})
        local ok = SkillSystem:upgradeSkill(1, 2)
        assert.is_true(ok)
        assert.equals(3, SkillSystem.skills[1].level)
        assert.equals(3, CurrencySystem:get("ether"))
    end)

    it("fails to upgrade without sufficient currency", function()
        SkillSystem.skills = {}
        CurrencySystem.balances = {ether = 1}
        SkillSystem:addSkill({name = "Bolt", rarity = "C"})
        local ok = SkillSystem:upgradeSkill(1, 5)
        assert.is_false(ok)
        assert.equals(1, SkillSystem.skills[1].level)
        assert.equals(1, CurrencySystem:get("ether"))
    end)
end)
