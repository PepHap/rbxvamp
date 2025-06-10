local LootSystem = require("src.LootSystem")
local CurrencySystem = require("src.CurrencySystem")
local PlayerLevelSystem = require("src.PlayerLevelSystem")
local RewardGaugeSystem = require("src.RewardGaugeSystem")
local LocationSystem = require("src.LocationSystem")
local LevelSystem = require("src.LevelSystem")

describe("LootSystem", function()
    before_each(function()
        CurrencySystem.balances = {}
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 0
        PlayerLevelSystem.nextExp = 100
        RewardGaugeSystem.gauge = 0
        RewardGaugeSystem.options = nil
        LevelSystem.currentLevel = 1
        LocationSystem.currentIndex = 1
    end)

    it("awards base loot on kill", function()
        LootSystem:onEnemyKilled({})
        assert.equals(1, CurrencySystem:get("gold"))
        assert.equals(5, PlayerLevelSystem.exp)
        assert.equals(10, RewardGaugeSystem.gauge)
    end)

    it("uses location currency", function()
        LocationSystem.currentIndex = 2
        LootSystem:onEnemyKilled({})
        assert.equals(1, CurrencySystem:get("ore"))
    end)

    it("scales rewards for bosses", function()
        LevelSystem.currentLevel = 3
        LootSystem:onEnemyKilled({type = "boss"})
        assert.equals(30, CurrencySystem:get("gold"))
        assert.equals(50, PlayerLevelSystem.exp)
    end)
end)
