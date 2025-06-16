local RewardGaugeUISystem = require("src.RewardGaugeUISystem")
local RewardGaugeSystem = require("src.RewardGaugeSystem")

describe("RewardGaugeUISystem", function()
    before_each(function()
        RewardGaugeUISystem.gui = nil
        RewardGaugeUISystem.gaugeLabel = nil
        RewardGaugeUISystem.optionButtons = nil
        RewardGaugeUISystem.visible = false
        RewardGaugeSystem.gauge = 0
        RewardGaugeSystem.maxGauge = 100
        RewardGaugeSystem.options = nil
    end)

    it("displays gauge value", function()
        RewardGaugeSystem.gauge = 50
        RewardGaugeUISystem:start()
        RewardGaugeUISystem:update()
        assert.equals("ScreenGui", RewardGaugeUISystem.gui.ClassName)
        assert.is_truthy(string.find(RewardGaugeUISystem.gaugeLabel.Text, "50/100"))
    end)

    it("shows options and selects reward", function()
        RewardGaugeSystem.options = {
            {slot = "Hat", item = {name = "Cap"}},
            {slot = "Weapon", item = {name = "Sword"}},
        }
        RewardGaugeUISystem:start()
        local opts = RewardGaugeUISystem:showOptions()
        assert.equals(2, #opts)
        assert.equals(2, #RewardGaugeUISystem.optionButtons)
        local chosen = RewardGaugeUISystem:choose(2)
        assert.equals("Sword", chosen.item.name)
        assert.is_nil(RewardGaugeSystem.options)
    end)
end)
