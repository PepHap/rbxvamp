local SkillTreeUISystem = require("src.SkillTreeUISystem")

describe("SkillTreeUISystem", function()
    before_each(function()
        SkillTreeUISystem.gui = nil
        SkillTreeUISystem.treeSystem = {skillSystem = {skills = {}}}
    end)

    it("starts and creates gui", function()
        SkillTreeUISystem:start()
        assert.is_not_nil(SkillTreeUISystem.gui)
    end)
end)
