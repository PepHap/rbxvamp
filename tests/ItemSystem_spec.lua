local ItemSystem = require("src.ItemSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("ItemSystem", function()
    it("has default empty slots", function()
        local items = ItemSystem.new()
        assert.is_nil(items.slots.Weapon)
    end)

    it("equips an item in a slot", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword"})
        assert.equals("Sword", items.slots.Weapon.name)
    end)

    it("unequips an item and returns it", function()
        local items = ItemSystem.new()
        items:equip("Hat", {name = "Cap"})
        local removed = items:unequip("Hat")
        assert.equals("Cap", removed.name)
        assert.is_nil(items.slots.Hat)
    end)

    it("upgrades an item when enough currency", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword"})
        CurrencySystem.balances = {gold = 5}
        local ok = items:upgradeItem("Weapon", 1, "gold")
        assert.is_true(ok)
        assert.equals(2, items.slots.Weapon.level)
        assert.equals(4, CurrencySystem:get("gold"))
    end)

    it("upgrades an item up to the maximum level", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword"})
        local cost = 0
        for lvl = 2, ItemSystem.maxLevel do
            cost = cost + (ItemSystem.upgradeCosts[lvl] or 0)
        end
        CurrencySystem.balances = {gold = cost}
        local ok = items:upgradeItem("Weapon", ItemSystem.maxLevel - 1, "gold")
        assert.is_true(ok)
        assert.equals(ItemSystem.maxLevel, items.slots.Weapon.level)
        assert.equals(0, CurrencySystem:get("gold"))
    end)

    it("fails upgrade without sufficient currency", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword"})
        CurrencySystem.balances = {gold = 0}
        local ok = items:upgradeItem("Weapon", 1, "gold")
        assert.is_false(ok)
        assert.equals(1, items.slots.Weapon.level)
        assert.equals(0, CurrencySystem:get("gold"))
    end)

    it("errors when using an invalid slot", function()
        local items = ItemSystem.new()
        assert.has_error(function()
            items:equip("Invalid", {name = "Thing"})
        end)
        assert.has_error(function()
            items:unequip("Invalid")
        end)
    end)

    it("prevents upgrading beyond the maximum level", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword", level = ItemSystem.maxLevel})
        CurrencySystem.balances = {gold = 100}
        local ok = items:upgradeItem("Weapon", 1, "gold")
        assert.is_false(ok)
        assert.equals(ItemSystem.maxLevel, items.slots.Weapon.level)
    end)
end)
