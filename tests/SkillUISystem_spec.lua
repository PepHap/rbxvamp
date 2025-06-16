local SkillUISystem = require("src.SkillUISystem")

describe("SkillUISystem", function()
    before_each(function()
        SkillUISystem.gui = nil
        SkillUISystem.skillSystem = {skills = {}}
        SkillUISystem.visible = false
    end)

    it("toggles visibility", function()
        SkillUISystem:start()
        assert.is_false(SkillUISystem.visible)
        SkillUISystem:toggle()
        assert.is_true(SkillUISystem.visible)
    end)
end)
