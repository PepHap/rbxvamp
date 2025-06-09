local AutoBattleSystem = require("../src/AutoBattleSystem")

describe("AutoBattleSystem", function()
    it("is disabled by default", function()
        assert.is_false(AutoBattleSystem.enabled)
    end)

    it("can be enabled and disabled", function()
        AutoBattleSystem.enabled = false
        AutoBattleSystem:enable()
        assert.is_true(AutoBattleSystem.enabled)
        AutoBattleSystem:disable()
        assert.is_false(AutoBattleSystem.enabled)
    end)
end)
