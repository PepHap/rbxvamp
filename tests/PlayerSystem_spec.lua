local PlayerSystem = require("src.PlayerSystem")
local LevelSystem = require("src.LevelSystem")
local AutoBattleSystem = require("src.AutoBattleSystem")
local EnemySystem = require("src.EnemySystem")

describe("PlayerSystem", function()
    before_each(function()
        PlayerSystem.maxHealth = 100
        PlayerSystem.health = 100
        LevelSystem.currentLevel = 1
        LevelSystem.killCount = 0
        LevelSystem.requiredKills = 15
        EnemySystem.enemies = {}
        AutoBattleSystem.damage = 1
        AutoBattleSystem.attackRange = 5
        AutoBattleSystem.playerPosition = {x = 0, y = 0}
        AutoBattleSystem.enabled = true
    end)

    it("reduces health when taking damage", function()
        PlayerSystem:takeDamage(30)
        assert.equals(70, PlayerSystem.health)
    end)

    it("resets on death and notifies LevelSystem", function()
        LevelSystem.currentLevel = 5
        LevelSystem.requiredKills = 35
        PlayerSystem.health = 5
        PlayerSystem:takeDamage(5)
        assert.equals(PlayerSystem.maxHealth, PlayerSystem.health)
        assert.equals(4, LevelSystem.currentLevel)
        assert.equals(30, LevelSystem.requiredKills)
    end)

    it("increments kills when auto battle defeats an enemy", function()
        LevelSystem.killCount = 0
        AutoBattleSystem.damage = 5
        local enemy = {health = 5, position = {x = 1, y = 0}}
        EnemySystem.enemies = {enemy}
        AutoBattleSystem:update(1)
        assert.equals(0, #EnemySystem.enemies)
        assert.equals(1, LevelSystem.killCount)
    end)
end)
