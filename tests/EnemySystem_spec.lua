local EnemySystem = require("../src/EnemySystem")

describe("EnemySystem", function()
    it("spawns wave and records level", function()
        EnemySystem.lastWaveLevel = nil
        EnemySystem:spawnWave(3)
        assert.equals(3, EnemySystem.lastWaveLevel)
    end)

    it("spawns boss and records type", function()
        EnemySystem.lastBossType = nil
        EnemySystem:spawnBoss("mini")
        assert.equals("mini", EnemySystem.lastBossType)
    end)
end)
