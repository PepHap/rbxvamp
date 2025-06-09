local ItemSystem = require("src.ItemSystem")

describe("ItemSystem", function()
    it("has default empty slots", function()
        local items = ItemSystem.new()
        assert.is_nil(items.slots.Weapon)
    end)

    it("equips an item in a slot", function()
        local items = ItemSystem.new()
        items:equip("Weapon", "Sword")
        assert.equals("Sword", items.slots.Weapon)
    end)
end)
