-- Use the same module paths as the production code so that the
-- EnemySystem instance referenced here matches the one used within
-- LevelSystem. This prevents state from diverging between two copies
-- of the module when the tests run.
local LevelSystem = require("src.LevelSystem")
local EnemySystem = require("src.EnemySystem")
local KeySystem = require("src.KeySystem")

describe("LevelSystem", function()
    it("starts at level 1", function()
        assert.equals(1, LevelSystem.currentLevel)
    end)

    it("advances the level", function()
        LevelSystem.currentLevel = 1
        local newLevel = LevelSystem:advance()
        assert.equals(2, LevelSystem.currentLevel)
        assert.equals(2, newLevel)
    end)

    it("advances after reaching required kills", function()
        LevelSystem.currentLevel = 1
        LevelSystem.killCount = 0
        LevelSystem.requiredKills = 2
        LevelSystem:addKill()
        LevelSystem:addKill()
        assert.equals(2, LevelSystem.currentLevel)
        assert.equals(0, LevelSystem.killCount)
    end)

    it("spawns a wave when advancing to a normal level", function()
        LevelSystem.currentLevel = 1
        EnemySystem.lastWaveLevel = nil
        LevelSystem:advance()
        assert.equals(2, EnemySystem.lastWaveLevel)
    end)

    it("spawns a mini boss on the 5th level", function()
        LevelSystem.currentLevel = 4
        EnemySystem.lastBossType = nil
        LevelSystem:advance()
        assert.equals("mini", EnemySystem.lastBossType)
    end)

    it("spawns a boss on the 10th level", function()
        LevelSystem.currentLevel = 9
        EnemySystem.lastBossType = nil
        LevelSystem:advance()
        assert.equals("boss", EnemySystem.lastBossType)
    end)

    it("spawns a location boss on the 30th level", function()
        LevelSystem.currentLevel = 29
        EnemySystem.lastBossType = nil
        KeySystem.keys = {}
        KeySystem:addKey("location", 1)
        LevelSystem:advance()
        assert.equals("location", EnemySystem.lastBossType)
    end)

    it("requires a location key to advance", function()
        LevelSystem.currentLevel = 29
        EnemySystem.lastBossType = nil
        KeySystem.keys = {}
        -- attempt without key should fail
        local res = LevelSystem:advance()
        assert.is_nil(res)
        assert.equals(29, LevelSystem.currentLevel)
        -- add key and try again
        KeySystem:addKey("location", 1)
        local ok = LevelSystem:advance()
        assert.equals(30, ok)
        assert.equals("location", EnemySystem.lastBossType)
    end)

    it("strengthens enemies each level", function()
        LevelSystem.currentLevel = 1
        EnemySystem.healthScale = 1
        EnemySystem.damageScale = 1
        LevelSystem:advance()
        local first = EnemySystem.enemies[1]
        local h1, d1 = first.health, first.damage
        LevelSystem:advance()
        local second = EnemySystem.enemies[1]
        assert.is_true(second.health > h1)
        assert.is_true(second.damage > d1)
    end)

    it("records highest cleared stage", function()
        LevelSystem.currentLevel = 1
        LevelSystem.highestClearedStage = 0
        LevelSystem:advance() -- to 2 clears stage 1
        assert.equals(1, LevelSystem.highestClearedStage)
    end)

    it("rolls back on mini boss death", function()
        LevelSystem.currentLevel = 5
        LevelSystem.requiredKills = 35
        LevelSystem:onPlayerDeath()
        assert.equals(4, LevelSystem.currentLevel)
        assert.equals(30, LevelSystem.requiredKills)
    end)

    it("applies scaling based on stage type", function()
        LevelSystem.currentLevel = 4
        EnemySystem.healthScale = 1
        EnemySystem.damageScale = 1
        LevelSystem:advance() -- to 5 -> mini boss
        local scaleAfterMini = EnemySystem.healthScale
        LevelSystem:advance() -- to 6 -> normal
        local scaleAfterNormal = EnemySystem.healthScale
        assert.is_true(scaleAfterNormal > scaleAfterMini)
        assert.is_true(scaleAfterMini > 1)
    end)
end)
