local RewardGaugeSystem = require("src.RewardGaugeSystem")

describe("RewardGaugeSystem", function()
    before_each(function()
        RewardGaugeSystem.gauge = 0
        RewardGaugeSystem.options = nil
        RewardGaugeSystem.maxGauge = 100
    end)

    it("accumulates points", function()
        RewardGaugeSystem:addPoints(40)
        RewardGaugeSystem:addPoints(50)
        assert.equals(90, RewardGaugeSystem.gauge)
        assert.is_nil(RewardGaugeSystem:getOptions())
    end)

    it("generates options when full", function()
        RewardGaugeSystem.gauge = 90
        RewardGaugeSystem:addPoints(20)
        local opts = RewardGaugeSystem:getOptions()
        assert.is_table(opts)
        assert.equals(0, RewardGaugeSystem.gauge)
        assert.equals(3, #opts)
    end)

    it("allows selecting an option and resets", function()
        RewardGaugeSystem.gauge = 99
        RewardGaugeSystem:addPoints(10)
        local opts = RewardGaugeSystem:getOptions()
        local chosen = RewardGaugeSystem:choose(1)
        assert.is_table(chosen)
        assert.is_nil(RewardGaugeSystem:getOptions())
        assert.equals(0, RewardGaugeSystem.gauge)
    end)
end)
