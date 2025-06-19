local CrystalExchangeUISystem = require("src.CrystalExchangeUISystem")
local CrystalExchangeSystem = require("src.CrystalExchangeSystem")

describe("CrystalExchangeUISystem", function()
    before_each(function()
        CrystalExchangeUISystem.gui = nil
        CrystalExchangeUISystem.visible = false
        CrystalExchangeUISystem.exchangeSystem = {
            buyTickets = function(_, kind, amount)
                CrystalExchangeUISystem.lastTicket = {kind, amount}
                return true
            end,
            buyCurrency = function(_, kind, amount)
                CrystalExchangeUISystem.lastCurrency = {kind, amount}
                return true
            end,
        }
    end)

    it("creates window and buttons", function()
        CrystalExchangeUISystem:start(CrystalExchangeUISystem.exchangeSystem)
        assert.is_table(CrystalExchangeUISystem.gui)
        assert.equals("ScreenGui", CrystalExchangeUISystem.gui.ClassName)
        assert.equals(4, #CrystalExchangeUISystem.buttons)
    end)

    it("handles ticket purchases", function()
        CrystalExchangeUISystem:start(CrystalExchangeUISystem.exchangeSystem)
        CrystalExchangeUISystem:buyTicket("skill")
        assert.same({"skill",1}, CrystalExchangeUISystem.lastTicket)
    end)

    it("handles currency purchases", function()
        CrystalExchangeUISystem:start(CrystalExchangeUISystem.exchangeSystem)
        CrystalExchangeUISystem:buyCurrency("gold")
        assert.same({"gold",1}, CrystalExchangeUISystem.lastCurrency)
    end)

    it("toggles visibility", function()
        CrystalExchangeUISystem:start(CrystalExchangeUISystem.exchangeSystem)
        CrystalExchangeUISystem:toggle()
        assert.is_true(CrystalExchangeUISystem.visible)
    end)
end)
