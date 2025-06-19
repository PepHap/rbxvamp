local UI = require("src.CrystalExchangeUISystem")
local Exchange = require("src.CrystalExchangeSystem")
local GachaSystem = require("src.GachaSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("CrystalExchangeUISystem", function()
    before_each(function()
        UI.gui = nil
        UI.visible = false
        GachaSystem.crystals = 5
        GachaSystem.tickets = {skill = 0, companion = 0, equipment = 0}
        CurrencySystem.balances = {}
    end)

    it("creates buttons and shows crystals", function()
        UI:start(Exchange)
        assert.is_table(UI.gui)
        assert.is_truthy(string.find(UI.crystalLabel.Text, "5"))
        assert.is_true(#UI.ticketButtons > 0)
        assert.is_true(#UI.currencyButtons > 0)
    end)

    it("buys ticket via button", function()
        UI:start(Exchange)
        local btn = UI.ticketButtons[1]
        if btn.onClick then btn.onClick() end
        assert.equals(4, GachaSystem.crystals)
        assert.equals(1, GachaSystem.tickets.skill)
    end)

    it("buys currency via button", function()
        UI:start(Exchange)
        local btn = UI.currencyButtons[1]
        if btn.onClick then btn.onClick() end
        assert.equals(4, GachaSystem.crystals)
        assert.equals(1, CurrencySystem:get("gold"))
    end)
end)
