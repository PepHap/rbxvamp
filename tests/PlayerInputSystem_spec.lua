local PlayerInputSystem = require("src.PlayerInputSystem")
local PlayerSystem = require("src.PlayerSystem")
local AutoBattleSystem = require("src.AutoBattleSystem")
local EnemySystem = require("src.EnemySystem")
local LevelSystem = require("src.LevelSystem")

-- Ensure loot/dungeon modules load so callbacks work
require("src.LootSystem")
require("src.DungeonSystem")

describe("PlayerInputSystem", function()
    before_each(function()
        PlayerSystem.position = {x = 0, y = 0, z = 0}
        PlayerInputSystem.playerPosition = PlayerSystem.position
        PlayerInputSystem.keyStates = {}
        AutoBattleSystem.enabled = false
        EnemySystem.enemies = {}
        LevelSystem.killCount = 0
    end)

    it("moves the player using key states", function()
        PlayerInputSystem:setKeyState("D", true)
        PlayerInputSystem:update(1)
        assert.equals(PlayerInputSystem.moveSpeed, PlayerSystem.position.x)
    end)

    it("attacks nearest enemy when space pressed", function()
        local enemy = {health = 1, position = {x = 0, y = 1}}
        EnemySystem.enemies = {enemy}
        PlayerInputSystem.attackRange = 2
        PlayerInputSystem:setKeyState("Space", true)
        PlayerInputSystem:update(0)
        assert.equals(0, #EnemySystem.enemies)
        assert.equals(1, LevelSystem.killCount)
    end)

    it("does not attack enemy when out of range", function()
        local enemy = {health = 1, position = {x = 10, y = 0}}
        EnemySystem.enemies = {enemy}
        PlayerInputSystem.attackRange = 2
        PlayerInputSystem:setKeyState("Space", true)
        PlayerInputSystem:update(0)
        assert.equals(1, #EnemySystem.enemies)
        assert.equals(0, LevelSystem.killCount)
    end)

    it("ignores input when auto battle is enabled", function()
        AutoBattleSystem.enabled = true
        PlayerInputSystem:setKeyState("D", true)
        PlayerInputSystem:update(1)
        assert.equals(0, PlayerSystem.position.x)
    end)

    it("toggles skill and companion UIs using keys", function()
        local SkillUISystem = require("src.SkillUISystem")
        local CompanionUISystem = require("src.CompanionUISystem")
        SkillUISystem.visible = false
        CompanionUISystem.visible = false
        PlayerInputSystem:setKeyState(PlayerInputSystem.skillKey, true)
        assert.is_true(SkillUISystem.visible)
        PlayerInputSystem:setKeyState(PlayerInputSystem.companionKey, true)
        assert.is_true(CompanionUISystem.visible)
    end)
end)
