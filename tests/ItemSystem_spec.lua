local ItemSystem = require("../src/ItemSystem")

describe("ItemSystem", function()
    it("has default empty slots", function()
        assert.is_nil(ItemSystem.slots.Weapon)
    end)

    it("equips an item in a slot", function()
        ItemSystem.slots.Weapon = nil
        ItemSystem:equip("Weapon", "Sword")
        assert.equals("Sword", ItemSystem.slots.Weapon)
    end)
end)
