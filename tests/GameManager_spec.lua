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

    it("serializes and restores game state", function()
        local ItemSystem = require("src.ItemSystem")
        local SkillSystem = require("src.SkillSystem")
        local CurrencySystem = require("src.CurrencySystem")
        local GachaSystem = require("src.GachaSystem")
        local CompanionSystem = require("src.CompanionSystem")
        local StatUpgradeSystem = require("src.StatUpgradeSystem")

        GameManager.itemSystem = ItemSystem.new()
        GameManager.inventory.itemSystem = GameManager.itemSystem
        GameManager.skillSystem = SkillSystem.new()
        GameManager.companionSystem.companions = {}
        CurrencySystem.balances = {gold = 5}
        GachaSystem.tickets.skill = 2
        StatUpgradeSystem.stats = {Health = {base = 10, level = 3}}
        local AchievementSystem = require("src.AchievementSystem")
        AchievementSystem.progress = {}
        AchievementSystem:start()
        AchievementSystem:addProgress("kills", 10)

        GameManager.itemSystem:equip("Weapon", {name = "Sword", slot = "Weapon"})
        GameManager.skillSystem:addSkill({name = "Fireball", rarity = "C"})
        GameManager.companionSystem:add({name = "Wolf", rarity = "C"})

        local data = GameManager:getSaveData()

        GameManager.itemSystem = ItemSystem.new()
        GameManager.inventory.itemSystem = GameManager.itemSystem
        GameManager.skillSystem = SkillSystem.new()
        GameManager.companionSystem.companions = {}
        CurrencySystem.balances = {}
        GachaSystem.tickets.skill = 0
        StatUpgradeSystem.stats = {Health = {base = 10, level = 1}}
        AchievementSystem.progress = {}
        AchievementSystem:start()

        GameManager:applySaveData(data)

        assert.equals("Sword", GameManager.itemSystem.slots.Weapon.name)
        assert.equals(1, #GameManager.skillSystem.skills)
        assert.equals(1, #GameManager.companionSystem.companions)
        assert.equals(5, CurrencySystem:get("gold"))
        assert.equals(2, GachaSystem.tickets.skill)
        assert.equals(3, StatUpgradeSystem.stats.Health.level)
        assert.equals(10, AchievementSystem.progress.kills_10.value)
    end)

    it("salvages inventory items via GameManager", function()
        local ItemSystem = require("src.ItemSystem")
        local Salvage = require("src.ItemSalvageSystem")
        local items = ItemSystem.new()
        items:addItem({name = "Cap", slot = "Hat", rarity = "C"})
        GameManager.itemSystem = items
        GameManager.inventory.itemSystem = items
        Salvage.called = false
        Salvage.salvageFromInventory = function(_, itemSys, index)
            Salvage.called = {itemSys, index}
            return true
        end
        GameManager.itemSalvageSystem = Salvage
        local ok = GameManager:salvageInventoryItem(1)
        assert.is_true(ok)
        assert.same({items, 1}, Salvage.called)
    end)

    it("salvages equipped items via GameManager", function()
        local ItemSystem = require("src.ItemSystem")
        local Salvage = require("src.ItemSalvageSystem")
        local items = ItemSystem.new()
        items:equip("Ring", {name = "Ring", slot = "Ring", rarity = "C"})
        GameManager.itemSystem = items
        GameManager.inventory.itemSystem = items
        Salvage.calledItem = nil
        Salvage.salvageItem = function(_, itm)
            Salvage.calledItem = itm
            return true
        end
        GameManager.itemSalvageSystem = Salvage
        local ok = GameManager:salvageEquippedItem("Ring")
        assert.is_true(ok)
        assert.equals("Ring", Salvage.calledItem.slot)

    end)
end)
