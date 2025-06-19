local AchievementSystem = require("src.AchievementSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("AchievementSystem", function()
    before_each(function()
        AchievementSystem.progress = {}
        CurrencySystem.balances = {}
        AchievementSystem:start()
    end)

    it("tracks kill progress", function()
        AchievementSystem:addProgress("kills", 5)
        assert.equals(5, AchievementSystem.progress.kills_10.value)
        AchievementSystem:addProgress("kills", 5)
        assert.is_true(AchievementSystem.progress.kills_10.completed)
    end)

    it("awards currency on claim", function()
        AchievementSystem:addProgress("kills", 10)
        local ok = AchievementSystem:claim("kills_10")
        assert.is_true(ok)
        assert.equals(10, CurrencySystem:get("gold"))
    end)

    it("does not allow double claiming", function()
        AchievementSystem:addProgress("kills", 10)
        assert.is_true(AchievementSystem:claim("kills_10"))
        assert.is_false(AchievementSystem:claim("kills_10"))
    end)

    it("saves and loads progress", function()
        AchievementSystem:addProgress("kills", 5)
        local data = AchievementSystem:saveData()
        AchievementSystem.progress = {}
        AchievementSystem:start()
        AchievementSystem:loadData(data)
        assert.equals(5, AchievementSystem.progress.kills_10.value)
    end)
end)
