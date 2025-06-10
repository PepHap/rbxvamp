local UISystem = require("src.UISystem")
local RewardGaugeSystem = require("src.RewardGaugeSystem")

describe("UISystem", function()
    before_each(function()
        RewardGaugeSystem.gauge = 0
        RewardGaugeSystem.options = nil
        UISystem.gui = nil
    end)

    it("returns nil when no reward options", function()
        RewardGaugeSystem.options = nil
        assert.is_nil(UISystem:showRewardOptions())
    end)

    it("shows and returns reward options", function()
        local opts = {
            {slot = "Hat", item = {name = "Cap"}},
            {slot = "Weapon", item = {name = "Sword"}},
        }
        RewardGaugeSystem.options = opts
        local ret = UISystem:showRewardOptions()
        assert.equals(opts, ret)
        assert.is_table(UISystem.gui)
        assert.equals("ScreenGui", UISystem.gui.ClassName)
        assert.is_table(UISystem.gui.rewardButtons[1])
        assert.equals("TextButton", UISystem.gui.rewardButtons[1].ClassName)
    end)

    it("selects a reward and clears options", function()
        RewardGaugeSystem.options = {
            {slot = "Hat", item = {name = "Cap"}},
            {slot = "Weapon", item = {name = "Sword"}},
        }
        local chosen = UISystem:selectReward(2)
        assert.equals("Sword", chosen.item.name)
        assert.is_nil(RewardGaugeSystem.options)
        assert.is_string(UISystem.gui.selectionLabel.Text)
    end)

    it("handles gacha result display", function()
        UISystem:displayGachaResult({name = "Fireball", rarity = "A"})
        assert.equals("TextLabel", UISystem.gui.gachaLabel.ClassName)
        assert.is_truthy(string.find(UISystem.gui.gachaLabel.Text, "Fireball"))
        UISystem:displayGachaResult(nil)
        assert.is_truthy(string.find(UISystem.gui.gachaLabel.Text, "no reward"))
    end)

    it("displays reward gauge value", function()
        RewardGaugeSystem.gauge = 50
        RewardGaugeSystem.maxGauge = 100
        UISystem:displayRewardGauge()
        assert.equals("TextLabel", UISystem.gaugeLabel.ClassName)
        assert.equals("Gauge: 50/100", UISystem.gaugeLabel.Text)
    end)

    it("creates buttons for item, skill and companion choices", function()
        local ib = UISystem:showItemChoice({name = "Sword"})
        local sb = UISystem:showSkillChoice({name = "Fireball"})
        local cb = UISystem:showCompanionChoice({name = "Wolf"})
        assert.equals("TextButton", ib.ClassName)
        assert.equals("Sword", ib.Text)
        assert.equals("Fireball", sb.Text)
        assert.equals("Wolf", cb.Text)
    end)
end)
