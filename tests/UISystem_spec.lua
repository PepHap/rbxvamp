local UISystem = require("src.UISystem")
local RewardGaugeSystem = require("src.RewardGaugeSystem")

describe("UISystem", function()
    before_each(function()
        RewardGaugeSystem.gauge = 0
        RewardGaugeSystem.options = nil
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
    end)

    it("selects a reward and clears options", function()
        RewardGaugeSystem.options = {
            {slot = "Hat", item = {name = "Cap"}},
            {slot = "Weapon", item = {name = "Sword"}},
        }
        local chosen = UISystem:selectReward(2)
        assert.equals("Sword", chosen.item.name)
        assert.is_nil(RewardGaugeSystem.options)
    end)

    it("handles gacha result display", function()
        assert.is_true(pcall(function()
            UISystem:displayGachaResult({name = "Fireball", rarity = "A"})
            UISystem:displayGachaResult(nil)
        end))
    end)
end)
