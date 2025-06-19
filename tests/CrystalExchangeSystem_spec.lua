local CrystalExchangeSystem = require("src.CrystalExchangeSystem")
local GachaSystem = require("src.GachaSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("CrystalExchangeSystem", function()
    before_each(function()
        GachaSystem.crystals = 10
        GachaSystem.tickets = {skill = 0, companion = 0, equipment = 0}
        CurrencySystem.balances = {}
    end)

    it("buys tickets when enough crystals", function()
        local ok = CrystalExchangeSystem:buyTickets("skill", 2)
        assert.is_true(ok)
        assert.equals(8, GachaSystem.crystals)
        assert.equals(2, GachaSystem.tickets.skill)
    end)

    it("fails to buy tickets without crystals", function()
        GachaSystem.crystals = 0
        local ok = CrystalExchangeSystem:buyTickets("companion", 1)
        assert.is_false(ok)
        assert.equals(0, GachaSystem.tickets.companion)
    end)

    it("buys upgrade currency", function()
        local ok = CrystalExchangeSystem:buyCurrency("gold", 3)
        assert.is_true(ok)
        assert.equals(7, GachaSystem.crystals)
        assert.equals(3, CurrencySystem:get("gold"))
    end)

    it("upgrades items with crystals", function()
        local ItemSystem = require("src.ItemSystem")
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword", slot = "Weapon"})
        local ok = CrystalExchangeSystem:upgradeItemWithCrystals(items, "Weapon", 1, "gold")
        assert.is_true(ok)
        assert.equals(2, items.slots.Weapon.level)
        assert.equals(9, GachaSystem.crystals)
    end)

    it("fails upgrade without enough crystals", function()
        local ItemSystem = require("src.ItemSystem")
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword", slot = "Weapon"})
        GachaSystem.crystals = 0
        local ok = CrystalExchangeSystem:upgradeItemWithCrystals(items, "Weapon", 1, "gold")
        assert.is_false(ok)
        assert.equals(1, items.slots.Weapon.level)
    end)

    it("sells inventory items for crystals", function()
        local ItemSystem = require("src.ItemSystem")
        local items = ItemSystem.new()
        items:addItem({name = "Cloth Cap", slot = "Hat", rarity = "C"})
        local ok = CrystalExchangeSystem:sellInventoryItem(items, 1)
        assert.is_true(ok)
        assert.equals(0, #items.inventory)
        assert.equals(11, GachaSystem.crystals)
    end)
end)
