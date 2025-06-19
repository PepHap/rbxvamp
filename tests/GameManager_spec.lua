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

    it("delegates ticket purchases to CrystalExchangeSystem", function()
        local CrystalExchangeSystem = require("src.CrystalExchangeSystem")
        CrystalExchangeSystem.last = nil
        CrystalExchangeSystem.buyTickets = function(_, kind, amount)
            CrystalExchangeSystem.last = {kind, amount}
            return true
        end
        local ok = GameManager:buyTickets("skill", 2)
        assert.is_true(ok)
        assert.same({"skill", 2}, CrystalExchangeSystem.last)
    end)

    it("delegates currency purchases to CrystalExchangeSystem", function()
        local CrystalExchangeSystem = require("src.CrystalExchangeSystem")
        CrystalExchangeSystem.last = nil
        CrystalExchangeSystem.buyCurrency = function(_, kind, amount)
            CrystalExchangeSystem.last = {kind, amount}
            return true
        end
        local ok = GameManager:buyCurrency("gold", 3)
        assert.is_true(ok)
        assert.same({"gold", 3}, CrystalExchangeSystem.last)
    end)

    it("upgrades items with crystals via GameManager", function()
        local ItemSystem = require("src.ItemSystem")
        local items = ItemSystem.new()
        items:equip("Weapon", {name = "Sword", slot = "Weapon"})
        GameManager.itemSystem = items
        local CrystalExchangeSystem = require("src.CrystalExchangeSystem")
        CrystalExchangeSystem.args = nil
        CrystalExchangeSystem.upgradeItemWithCrystals = function(_, itemSys, slot, amount, currency)
            CrystalExchangeSystem.args = {itemSys, slot, amount, currency}
            return true
        end
        local ok = GameManager:upgradeItemWithCrystals("Weapon", 1, "gold")
        assert.is_true(ok)
        assert.same({items, "Weapon", 1, "gold"}, CrystalExchangeSystem.args)
    end)
end)
