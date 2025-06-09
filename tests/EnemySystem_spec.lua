local EnemySystem = require("src.EnemySystem")

describe("EnemySystem", function()
    it("spawns wave and records level", function()
        EnemySystem.lastWaveLevel = nil
        EnemySystem:spawnWave(3)
        assert.equals(3, EnemySystem.lastWaveLevel)
    end)

    it("creates enemies with attributes when spawning a wave", function()
        EnemySystem:spawnWave(2)
        assert.equals(2, #EnemySystem.enemies)
        local first = EnemySystem.enemies[1]
        assert.equals(14, first.health)
        assert.equals(3, first.damage)
        assert.same({x = 1, y = 0, z = 0}, first.position)
        assert.is_nil(first.type)
    end)

    it("spawns boss and records type", function()
        EnemySystem.lastBossType = nil
        EnemySystem:spawnBoss("mini")
        assert.equals("mini", EnemySystem.lastBossType)
    end)

    it("creates a boss with attributes", function()
        EnemySystem:spawnBoss("mini")
        assert.equals(1, #EnemySystem.enemies)
        local boss = EnemySystem.enemies[1]
        assert.equals(50, boss.health)
        assert.equals(5, boss.damage)
        assert.equals("mini", boss.type)
        assert.same({x = 0, y = 0, z = 0}, boss.position)
    end)
end)
