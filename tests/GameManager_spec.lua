local GameManager = require("src.GameManager")

describe("GameManager", function()
    it("exposes a start function", function()
        assert.is_function(GameManager.start)
    end)

    it("exposes an update function", function()
        assert.is_function(GameManager.update)
    end)

    it("start and update do not error", function()
        assert.is_true(pcall(function() GameManager:start() end))
        assert.is_true(pcall(function() GameManager:update(0.1) end))
    end)

    it("spawns enemies on start", function()
        local EnemySystem = require("src.EnemySystem")
        EnemySystem.enemies = {}
        GameManager:start()
        assert.is_true(#EnemySystem.enemies > 0)
    end)

    it("registers and starts added systems", function()
        local started = 0
        local mockSystem = {
            start = function()
                started = started + 1
            end
        }

        GameManager:addSystem("Mock", mockSystem)

        -- Verify the system tables were updated
        assert.equals(mockSystem, GameManager.systems.Mock)
        assert.equals("Mock", GameManager.order[#GameManager.order])

        GameManager:start()
        assert.equals(1, started)
    end)

    it("includes Level and Key systems", function()
        local LevelSystem = require("src.LevelSystem")
        local KeySystem = require("src.KeySystem")
        assert.equals(LevelSystem, GameManager.systems.Level)
        assert.equals(KeySystem, GameManager.systems.Keys)
    end)

    it("registers the Dungeon system", function()
        local DungeonSystem = require("src.DungeonSystem")
        assert.equals(DungeonSystem, GameManager.systems.Dungeon)
    end)

    it("includes the UI system", function()
        local UISystem = require("src.UISystem")
        assert.equals(UISystem, GameManager.systems.UI)
    end)

    it("registers the main menu UI", function()
        local MenuUISystem = require("src.MenuUISystem")
        assert.equals(MenuUISystem, GameManager.systems.MenuUI)
    end)
end)
