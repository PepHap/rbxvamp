local SalvageSystem = require("src.ItemSalvageSystem")
local ItemSystem = require("src.ItemSystem")
local CurrencySystem = require("src.CurrencySystem")
local GachaSystem = require("src.GachaSystem")

describe("ItemSalvageSystem", function()
    before_each(function()
        CurrencySystem.balances = {gold = 0}
        GachaSystem.crystals = 0
    end)

    it("salvages an item directly", function()
        local ok = SalvageSystem:salvageItem({rarity="B", level=2})
        assert.is_true(ok)
        assert.equals(4, CurrencySystem:get("gold"))
        assert.equals(2, GachaSystem.crystals)
    end)

    it("salvages from inventory", function()
        local items = ItemSystem.new()
        items:addItem({name="Sword", slot="Weapon", rarity="C"})
        local ok = SalvageSystem:salvageFromInventory(items, 1)
        assert.is_true(ok)
        assert.equals(0, #items.inventory)
        assert.equals(1, CurrencySystem:get("gold"))
    end)
end)
