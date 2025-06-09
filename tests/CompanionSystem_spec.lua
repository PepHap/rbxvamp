local CompanionSystem = require("../src/CompanionSystem")

describe("CompanionSystem", function()
    it("can add a companion", function()
        CompanionSystem.companions = {}
        CompanionSystem:add({name = "Ghost", rarity = "B"})
        local c = CompanionSystem.companions[1]
        assert.equals("Ghost", c.name)
        assert.equals("B", c.rarity)
        assert.equals(1, c.level)
    end)

    it("upgrades a companion with enough currency", function()
        CompanionSystem.companions = {}
        CompanionSystem:add({name = "Fairy", rarity = "C"})
        local ok = CompanionSystem:upgradeCompanion(1, 2, 3)
        assert.is_true(ok)
        assert.equals(3, CompanionSystem.companions[1].level)
    end)

    it("fails upgrade when currency is insufficient", function()
        CompanionSystem.companions = {}
        CompanionSystem:add({name = "Imp", rarity = "C"})
        local ok = CompanionSystem:upgradeCompanion(1, 4, 1)
        assert.is_false(ok)
        assert.equals(1, CompanionSystem.companions[1].level)
    end)
end)
