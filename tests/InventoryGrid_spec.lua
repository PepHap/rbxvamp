local InventoryGrid = require("src.InventoryGrid")

describe("InventoryGrid", function()
    it("shows item level in cell text", function()
        local grid = InventoryGrid.new()
        grid.useRobloxObjects = false
        grid:create({ClassName="Frame"}, nil)
        grid:ensureCells(1)
        grid:updateCell(1, {name="Sword", level=3})
        assert.equals("Sword Lv3", grid.cells[1].Text)
    end)
end)
