local LevelSystem = require("src.LevelSystem")
local EnemySystem = require("src.EnemySystem")

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
        LevelSystem:advance()
        assert.equals("location", EnemySystem.lastBossType)
    end)

    it("strengthens monsters based on current level", function()
        LevelSystem.currentLevel = 3
        EnemySystem:reset()
        LevelSystem:strengthenMonsters()
        assert.equals(300, EnemySystem.enemyHealth)
        assert.equals(30, EnemySystem.enemyDamage)
    end)

    it("applies scaled stats when spawning", function()
        LevelSystem.currentLevel = 1
        EnemySystem:reset()
        EnemySystem.lastWaveStats = nil
        LevelSystem:advance() -- to level 2
        assert.equals(2, EnemySystem.lastWaveLevel)
        assert.equals(EnemySystem.enemyHealth, EnemySystem.lastWaveStats.health)
        assert.equals(EnemySystem.enemyDamage, EnemySystem.lastWaveStats.damage)
    end)
end)
