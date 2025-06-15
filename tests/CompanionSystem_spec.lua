local CompanionSystem = require("src.CompanionSystem")
local CurrencySystem = require("src.CurrencySystem")

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
        CurrencySystem.balances = {ether = 5}
        CompanionSystem:add({name = "Fairy", rarity = "C"})
        local ok = CompanionSystem:upgradeCompanion(1, 2)
        assert.is_true(ok)
        assert.equals(3, CompanionSystem.companions[1].level)
        assert.equals(3, CurrencySystem:get("ether"))
    end)

    it("fails upgrade when currency is insufficient", function()
        CompanionSystem.companions = {}
        CurrencySystem.balances = {ether = 1}
        CompanionSystem:add({name = "Imp", rarity = "C"})
        local ok = CompanionSystem:upgradeCompanion(1, 4)
        assert.is_false(ok)
        assert.equals(1, CompanionSystem.companions[1].level)
        assert.equals(1, CurrencySystem:get("ether"))
    end)

    it("rejects invalid upgrade amounts", function()
        CompanionSystem.companions = {}
        CurrencySystem.balances = {ether = 5}
        CompanionSystem:add({name = "Golem", rarity = "B"})
        local ok = CompanionSystem:upgradeCompanion(1, "bad")
        assert.is_false(ok)
        assert.equals(1, CompanionSystem.companions[1].level)
    end)
end)
