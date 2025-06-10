local DungeonSystem = require("src.DungeonSystem")
local CurrencySystem = require("src.CurrencySystem")
local KeySystem = require("src.KeySystem")

describe("DungeonSystem", function()
    before_each(function()
        DungeonSystem.active = nil
        DungeonSystem.killCount = 0
        CurrencySystem.balances = {}
        KeySystem.keys = {}
    end)

    it("starts a dungeon when key available", function()
        KeySystem:addKey("ore", 1)
        local ok = DungeonSystem:start("ore")
        assert.is_true(ok)
        assert.equals("ore", DungeonSystem.active)
    end)

    it("fails to start without key", function()
        local ok = DungeonSystem:start("ore")
        assert.is_false(ok)
        assert.is_nil(DungeonSystem.active)
    end)

    it("completes after required kills and grants reward", function()
        KeySystem:addKey("ore", 1)
        DungeonSystem:start("ore")
        DungeonSystem:addKill()
        DungeonSystem:addKill()
        DungeonSystem:addKill()
        assert.is_nil(DungeonSystem.active)
        assert.equals(5, CurrencySystem:get("ore"))
    end)

    it("aborts without reward", function()
        KeySystem:addKey("ore", 1)
        DungeonSystem:start("ore")
        DungeonSystem:abort()
        DungeonSystem:addKill()
        assert.is_nil(DungeonSystem.active)
        assert.equals(0, CurrencySystem:get("ore"))
    end)
end)
