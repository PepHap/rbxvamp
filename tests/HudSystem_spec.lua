local HudSystem = require("src.HudSystem")
local PlayerLevelSystem = require("src.PlayerLevelSystem")
local CurrencySystem = require("src.CurrencySystem")
local LocationSystem = require("src.LocationSystem")

describe("HudSystem", function()
    before_each(function()
        HudSystem.gui = nil
        HudSystem.levelLabel = nil
        HudSystem.currencyLabel = nil
        HudSystem.autoButton = nil
        HudSystem.attackButton = nil
        HudSystem.gachaButton = nil
        HudSystem.inventoryButton = nil
        HudSystem.rewardButton = nil
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 0
        PlayerLevelSystem.nextExp = 100
        CurrencySystem.balances = {}
        LocationSystem.currentIndex = 1
        local RewardGaugeUISystem = require("src.RewardGaugeUISystem")
        RewardGaugeUISystem.visible = false
    end)

    it("creates labels on start", function()
        HudSystem:start()
        assert.is_table(HudSystem.gui)
        assert.equals("TextLabel", HudSystem.levelLabel.ClassName)
        assert.equals("TextLabel", HudSystem.currencyLabel.ClassName)
        assert.equals("TextButton", HudSystem.autoButton.ClassName)
        assert.equals("TextButton", HudSystem.attackButton.ClassName)
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

    it("creates attack button and triggers manual attack", function()
        local PlayerInputSystem = require("src.PlayerInputSystem")
        local called = false
        local old = PlayerInputSystem.manualAttack
        PlayerInputSystem.manualAttack = function()
            called = true
        end
        HudSystem:start()
        assert.equals("TextButton", HudSystem.attackButton.ClassName)
        HudSystem.attackButton.onClick()
        PlayerInputSystem.manualAttack = old
        assert.is_true(called)
    end)

    it("ignores attack button when auto battle enabled", function()
        local PlayerInputSystem = require("src.PlayerInputSystem")
        local called = false
        local old = PlayerInputSystem.manualAttack
        PlayerInputSystem.manualAttack = function()
            called = true
        end
        local AutoBattleSystem = require("src.AutoBattleSystem")
        AutoBattleSystem.enabled = true
        HudSystem:start()
        HudSystem.attackButton.onClick()
        PlayerInputSystem.manualAttack = old
        AutoBattleSystem.enabled = false
        assert.is_false(called)
    end)

    it("toggles various UI windows", function()
        local GachaUISystem = require("src.GachaUISystem")
        local InventoryUISystem = require("src.InventoryUISystem")
        local RewardGaugeUISystem = require("src.RewardGaugeUISystem")
        local SkillUISystem = require("src.SkillUISystem")
        local CompanionUISystem = require("src.CompanionUISystem")
        GachaUISystem.visible = false
        InventoryUISystem.visible = false
        RewardGaugeUISystem.visible = false
        SkillUISystem.visible = false
        CompanionUISystem.visible = false
        HudSystem:start()
        HudSystem.gachaButton.onClick()
        assert.is_true(GachaUISystem.visible)
        HudSystem.inventoryButton.onClick()
        assert.is_true(InventoryUISystem.visible)
        HudSystem.rewardButton.onClick()
        assert.is_true(RewardGaugeUISystem.visible)
        HudSystem.skillButton.onClick()
        assert.is_true(SkillUISystem.visible)
        HudSystem.companionButton.onClick()
        assert.is_true(CompanionUISystem.visible)
    end)
end)
