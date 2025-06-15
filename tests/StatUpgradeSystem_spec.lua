local StatUpgradeSystem = require("src.StatUpgradeSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("StatUpgradeSystem", function()
    before_each(function()
        StatUpgradeSystem.stats = {}
        CurrencySystem.balances = {}
    end)

    it("adds a new stat", function()
        StatUpgradeSystem:addStat("attack", 10)
        local s = StatUpgradeSystem.stats.attack
        assert.is_not_nil(s)
        assert.equals(1, s.level)
        assert.equals(10, s.base)
    end)

    it("upgrades a stat when currency available", function()
        StatUpgradeSystem:addStat("attack", 10)
        CurrencySystem.balances = {gold = 5}
        local ok = StatUpgradeSystem:upgradeStat("attack", 2, "gold")
        assert.is_true(ok)
        assert.equals(3, StatUpgradeSystem.stats.attack.level)
        assert.equals(3, CurrencySystem:get("gold"))
    end)

    it("fails upgrade with insufficient currency", function()
        StatUpgradeSystem:addStat("attack", 10)
        CurrencySystem.balances = {gold = 1}
        local ok = StatUpgradeSystem:upgradeStat("attack", 2, "gold")
        assert.is_false(ok)
        assert.equals(1, StatUpgradeSystem.stats.attack.level)
    end)

    it("rejects invalid upgrade amounts", function()
        StatUpgradeSystem:addStat("defense", 5)
        CurrencySystem.balances = {gold = 10}
        local ok = StatUpgradeSystem:upgradeStat("defense", "bad", "gold")
        assert.is_false(ok)
        assert.equals(1, StatUpgradeSystem.stats.defense.level)
    end)
end)
