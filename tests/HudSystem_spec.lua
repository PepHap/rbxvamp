local HudSystem = require("src.HudSystem")
local PlayerLevelSystem = require("src.PlayerLevelSystem")
local CurrencySystem = require("src.CurrencySystem")
local LocationSystem = require("src.LocationSystem")

describe("HudSystem", function()
    before_each(function()
        HudSystem.gui = nil
        HudSystem.levelLabel = nil
        HudSystem.currencyLabel = nil
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 0
        PlayerLevelSystem.nextExp = 100
        CurrencySystem.balances = {}
        LocationSystem.currentIndex = 1
    end)

    it("creates labels on start", function()
        HudSystem:start()
        assert.is_table(HudSystem.gui)
        assert.equals("TextLabel", HudSystem.levelLabel.ClassName)
        assert.equals("TextLabel", HudSystem.currencyLabel.ClassName)
    end)

    it("updates label text", function()
        PlayerLevelSystem.level = 2
        PlayerLevelSystem.exp = 50
        PlayerLevelSystem.nextExp = 100
        CurrencySystem.balances.gold = 10
        HudSystem:start()
        HudSystem:update()
        assert.matches("Lv%.2", HudSystem.levelLabel.Text)
        assert.is_truthy(string.find(HudSystem.currencyLabel.Text, "gold"))
    end)
end)
