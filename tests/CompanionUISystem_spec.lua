local CompanionUISystem = require("src.CompanionUISystem")

describe("CompanionUISystem", function()
    before_each(function()
        CompanionUISystem.gui = nil
        CompanionUISystem.companionSystem = {companions = {}}
        CompanionUISystem.visible = false
    end)

    it("toggles visibility", function()
        CompanionUISystem:start()
        assert.is_false(CompanionUISystem.visible)
        CompanionUISystem:toggle()
        assert.is_true(CompanionUISystem.visible)
    end)
end)
