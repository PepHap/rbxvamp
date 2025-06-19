local InventoryModule = require("src.InventoryModule")
local StatUpgradeSystem = require("src.StatUpgradeSystem")

describe("InventoryModule", function()
    before_each(function()
        StatUpgradeSystem.stats = {Health = {base = 10, level = 2}}
    end)

    it("adds items to inventory", function()
        local inv = InventoryModule.new(StatUpgradeSystem)
        inv:AddItem({name = "Sword"})
        assert.equals(1, #inv.itemSystem.inventory)
    end)

    it("equips and removes items", function()
        local inv = InventoryModule.new(StatUpgradeSystem)
        inv:EquipItem("Hat", {name = "Cap"})
        assert.equals("Cap", inv.itemSystem.slots.Hat.name)
        local itm = inv:RemoveItem("Hat")
        assert.equals("Cap", itm.name)
        assert.is_nil(inv.itemSystem.slots.Hat)
    end)

    it("returns combined stats", function()
        local inv = InventoryModule.new(StatUpgradeSystem)
        inv:EquipItem("Hat", {name = "Cap", level = 2, stats = {Health = 5}})
        local stats = inv:GetStats()
        -- base health = 10 * level 2 = 20, item contributes 5 *1.1 = 5.5
        assert.is_true(math.abs(stats.Health - 25.5) < 0.01)
    end)
end)

