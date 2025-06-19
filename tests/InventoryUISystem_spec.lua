local InventoryUISystem = require("src.InventoryUISystem")
local ItemSystem = require("src.ItemSystem")

describe("InventoryUISystem", function()
    before_each(function()
        InventoryUISystem.gui = nil
        InventoryUISystem.itemSystem = nil
        InventoryUISystem.visible = false
        InventoryUISystem.page = 1
        InventoryUISystem.selectedSlot = nil
        InventoryUISystem.pendingIndex = nil
        InventoryUISystem.statSystem = nil
        InventoryUISystem.setSystem = nil
    end)

    it("initializes gui and navigation buttons", function()
        local items = ItemSystem.new()
        InventoryUISystem:start(items)
        assert.equals("ScreenGui", InventoryUISystem.gui.ClassName)
        assert.is_table(InventoryUISystem.window.PrevPage)
        assert.is_table(InventoryUISystem.window.NextPage)
    end)

    it("equips inventory item into a slot", function()
        local items = ItemSystem.new()
        table.insert(items.inventory, {name = "Sword"})
        InventoryUISystem:start(items)
        InventoryUISystem:selectInventory(1)
        assert.equals(1, InventoryUISystem.pendingIndex)
        InventoryUISystem:selectSlot("Weapon")
        assert.is_nil(InventoryUISystem.pendingIndex)
        assert.equals("Sword", items.slots.Weapon.name)
    end)

    it("toggles visibility", function()
        local items = ItemSystem.new()
        InventoryUISystem:start(items)
        assert.is_false(InventoryUISystem.visible)
        InventoryUISystem:toggle()
        assert.is_true(InventoryUISystem.visible)
    end)

    it("upgrades selected slot", function()
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword", slot = "Weapon"})
        local CurrencySystem = require("src.CurrencySystem")
        CurrencySystem.balances = {gold = 5}
        InventoryUISystem:start(items)
        local ok = InventoryUISystem:upgradeSlot("Weapon")
        assert.is_true(ok)
        assert.equals(2, items.slots.Weapon.level)
    end)
end)

