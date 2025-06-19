local AdminConsole = require("src.AdminConsoleSystem")

describe("AdminConsoleSystem", function()
    before_each(function()
        AdminConsole.gui = nil
        AdminConsole.visible = false
        AdminConsole.adminIds = {1}
    end)

    it("creates gui and toggles visibility", function()
        AdminConsole:start(nil, {1})
        assert.is_table(AdminConsole.gui)
        AdminConsole:toggle()
        assert.is_true(AdminConsole.visible)
    end)

    it("executes commands", function()
        AdminConsole:start(nil, {1})
        local result = AdminConsole:runCommand("test")
        assert.is_truthy(string.find(result, "Executed"))
    end)

    it("handles exchange and salvage commands", function()
        local gm = {
            buyTicketsCalled = false,
            buyCurrencyCalled = false,
            upgradeItemWithCrystalsCalled = false,
            salvageInventoryItemCalled = false,
            salvageEquippedItemCalled = false,
            buyTickets = function(self, kind, amount)
                self.buyTicketsCalled = {kind, amount}
                return true
            end,
            buyCurrency = function(self, kind, amount)
                self.buyCurrencyCalled = {kind, amount}
                return true
            end,
            upgradeItemWithCrystals = function(self, slot, amount, cur)
                self.upgradeItemWithCrystalsCalled = {slot, amount, cur}
                return true
            end,
            salvageInventoryItem = function(self, idx)
                self.salvageInventoryItemCalled = idx
                return true
            end,
            salvageEquippedItem = function(self, slot)
                self.salvageEquippedItemCalled = slot
                return true
            end,
        }
        AdminConsole:start(gm, {1})
        AdminConsole:runCommand("buyticket skill 2")
        AdminConsole:runCommand("buycurrency gold 3")
        AdminConsole:runCommand("upgradec Weapon 1 gold")
        AdminConsole:runCommand("salvageinv 1")
        AdminConsole:runCommand("salvageslot Hat")
        assert.same({"skill",2}, gm.buyTicketsCalled)
        assert.same({"gold",3}, gm.buyCurrencyCalled)
        assert.same({"Weapon",1,"gold"}, gm.upgradeItemWithCrystalsCalled)
        assert.equals(1, gm.salvageInventoryItemCalled)
        assert.equals("Hat", gm.salvageEquippedItemCalled)
    end)
end)
