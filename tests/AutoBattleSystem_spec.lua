local AutoBattleSystem = require("../src/AutoBattleSystem")
local EnemySystem = require("../src/EnemySystem")


describe("AutoBattleSystem", function()
    it("is disabled by default", function()
        assert.is_false(AutoBattleSystem.enabled)
    end)

    it("can be enabled and disabled", function()
        AutoBattleSystem.enabled = false
        AutoBattleSystem:enable()
        assert.is_true(AutoBattleSystem.enabled)
        AutoBattleSystem:disable()
        assert.is_false(AutoBattleSystem.enabled)
    end)

    it("does not act when disabled", function()
        AutoBattleSystem.enabled = false
        AutoBattleSystem.playerPosition = {x = 0, y = 0}
        AutoBattleSystem.lastAttackTarget = nil
        EnemySystem.enemies = {{x = 1, y = 0}}
        AutoBattleSystem:update(1)
        assert.is_nil(AutoBattleSystem.lastAttackTarget)
        assert.equals(0, AutoBattleSystem.playerPosition.x)
    end)

    it("moves toward nearest enemy when out of range", function()
        AutoBattleSystem.enabled = true
        AutoBattleSystem.playerPosition = {x = 0, y = 0}
        AutoBattleSystem.moveSpeed = 1
        AutoBattleSystem.attackRange = 2
        EnemySystem.enemies = {{x = 10, y = 0}}
        AutoBattleSystem:update(1)
        assert.is_nil(AutoBattleSystem.lastAttackTarget)
        assert.equals(1, AutoBattleSystem.playerPosition.x)
    end)

    it("attacks enemy when in range", function()
        AutoBattleSystem.enabled = true
        AutoBattleSystem.playerPosition = {x = 0, y = 0}
        AutoBattleSystem.attackRange = 5
        local enemy = {x = 1, y = 0}
        EnemySystem.enemies = {enemy}
        AutoBattleSystem:update(1)
        assert.are.equal(enemy, AutoBattleSystem.lastAttackTarget)
        assert.equals(0, AutoBattleSystem.playerPosition.x)
    end)
end)
