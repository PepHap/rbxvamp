local CurrencySystem = require("src.CurrencySystem")

describe("CurrencySystem", function()
    it("adds and retrieves currency", function()
        CurrencySystem.balances = {}
        CurrencySystem:add("gold", 10)
        assert.equals(10, CurrencySystem:get("gold"))
    end)

    it("spends currency when enough balance", function()
        CurrencySystem.balances = {gold = 5}
        local ok = CurrencySystem:spend("gold", 3)
        assert.is_true(ok)
        assert.equals(2, CurrencySystem:get("gold"))
    end)

    it("fails to spend when insufficient", function()
        CurrencySystem.balances = {gold = 2}
        local ok = CurrencySystem:spend("gold", 5)
        assert.is_false(ok)
        assert.equals(2, CurrencySystem:get("gold"))
    end)

    it("handles non-number amounts", function()
        CurrencySystem.balances = {}
        CurrencySystem:add("gold", {})
        assert.equals(0, CurrencySystem:get("gold"))
    end)
end)
