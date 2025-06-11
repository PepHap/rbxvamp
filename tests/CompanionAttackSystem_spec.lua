local CompanionAttackSystem = require("src.CompanionAttackSystem")
local CompanionSystem = require("src.CompanionSystem")
local AutoBattleSystem = require("src.AutoBattleSystem")
local EnemySystem = require("src.EnemySystem")
local LevelSystem = require("src.LevelSystem")

describe("CompanionAttackSystem", function()
    before_each(function()
        CompanionSystem.companions = {}
        CompanionAttackSystem.positions = {}
        EnemySystem.enemies = {}
        AutoBattleSystem.playerPosition = {x = 0, y = 0}
        LevelSystem.killCount = 0
    end)

    it("initializes companion positions", function()
        CompanionSystem.companions = {{name = "Wolf", level = 1}}
        CompanionAttackSystem:start(CompanionSystem)
        assert.same({{x = 0, y = 0}}, CompanionAttackSystem.positions)
    end)

    it("moves companions toward the player", function()
        CompanionSystem.companions = {{name = "Wolf", level = 1}}
        AutoBattleSystem.playerPosition = {x = 5, y = 0}
        CompanionAttackSystem:start(CompanionSystem)
        local pos = CompanionAttackSystem.positions[1]
        pos.x = 0
        CompanionAttackSystem:update(1)
        assert.is_true(pos.x > 0)
    end)

    it("damages enemies in range", function()
        CompanionSystem.companions = {{name = "Wolf", level = 1}}
        CompanionAttackSystem:start(CompanionSystem)
        local enemy = {position = {x = 1, y = 0}, health = 5}
        EnemySystem.enemies = {enemy}
        CompanionAttackSystem:update(1)
        assert.is_true(enemy.health < 5)
    end)

    it("kills enemies and awards kill count", function()
        CompanionSystem.companions = {{name = "Wolf", level = 1}}
        CompanionAttackSystem:start(CompanionSystem)
        local enemy = {position = {x = 1, y = 0}, health = 1}
        EnemySystem.enemies = {enemy}
        LevelSystem.killCount = 0
        CompanionAttackSystem:update(1)
        assert.equals(0, #EnemySystem.enemies)
        assert.equals(1, LevelSystem.killCount)
    end)
end)

