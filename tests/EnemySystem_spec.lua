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
        assert.equals("Enemy 1", first.name)
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
        assert.equals("Mini Boss", boss.name)
    end)

    it("returns nearest enemy from a spawned wave", function()
        EnemySystem:spawnWave(3)
        local nearest = EnemySystem:getNearestEnemy({x = 2.1, y = 0})
        assert.are.equal(EnemySystem.enemies[2], nearest)
    end)

    it("returns nearest enemy among arbitrary positions", function()
        EnemySystem.enemies = {
            {position = {x = -5, y = 0}},
            {position = {x = 10, y = 0}},
            {position = {x = 0, y = 0}}
        }
        local nearest = EnemySystem:getNearestEnemy({x = 1, y = 0})
        assert.are.equal(EnemySystem.enemies[3], nearest)
    end)

    it("spawns models when enabled", function()
        EnemySystem.spawnModels = true
        EnemySystem:spawnWave(1)
        local enemy = EnemySystem.enemies[1]
        assert.is_table(enemy.model)
        assert.same(enemy.position, enemy.model.primaryPart.position)
        assert.equals(enemy.name, enemy.model.billboardGui.textLabel.text)
    end)

    it("skips model creation when disabled", function()
        EnemySystem.spawnModels = false
        EnemySystem:spawnBoss("mini")
        assert.is_nil(EnemySystem.enemies[1].model)
        assert.equals(1, #EnemySystem.enemies)
        EnemySystem.spawnModels = true
    end)

    it("labels boss models when spawned", function()
        EnemySystem.spawnModels = true
        EnemySystem:spawnBoss("mini")
        local boss = EnemySystem.enemies[1]
        assert.equals(boss.name, boss.model.billboardGui.textLabel.text)
    end)

    it("computes a path toward the player on update", function()
        local AutoBattleSystem = require("src.AutoBattleSystem")
        AutoBattleSystem.playerPosition = {x = 5, y = 0}
        local enemy = {position = {x = 0, y = 0, z = 0}, model = {primaryPart = {position = {x = 0, y = 0, z = 0}}}}
        EnemySystem.enemies = {enemy}
        EnemySystem:update(1)
        assert.is_table(enemy.path)
        assert.equals(2, #enemy.path)
    end)

    it("moves enemies toward the player", function()
        local AutoBattleSystem = require("src.AutoBattleSystem")
        AutoBattleSystem.playerPosition = {x = 3, y = 0}
        local enemy = {position = {x = 0, y = 0, z = 0}, model = {primaryPart = {position = {x = 0, y = 0, z = 0}}}}
        EnemySystem.enemies = {enemy}
        local before = math.sqrt((enemy.position.x - 3)^2 + (enemy.position.y)^2)
        EnemySystem:update(1)
        local after = math.sqrt((enemy.position.x - 3)^2 + (enemy.position.y)^2)
        assert.is_true(after < before)
    end)
end)
