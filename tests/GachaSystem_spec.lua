local GachaSystem = require("src.GachaSystem")

describe("GachaSystem", function()
    it("rolls rarities based on weight order", function()
        local counts = {}
        for i=1,1000 do
            local r = GachaSystem:rollRarity()
            counts[r] = (counts[r] or 0) + 1
        end
        assert.is_true((counts.C or 0) > (counts.D or 0))
        assert.is_true((counts.D or 0) > (counts.B or 0))
    end)

    it("returns a skill using tickets", function()
        GachaSystem.tickets.skill = 1
        local reward = GachaSystem:rollSkill()
        assert.is_table(reward)
        assert.is_string(reward.name)
    end)

    it("returns equipment when rolling a slot", function()
        GachaSystem.tickets.equipment = 1
        local reward = GachaSystem:rollEquipment("Weapon")
        assert.is_table(reward)
        assert.equals("Wooden Sword", reward.name)
    end)

    it("stores rolled equipment in the inventory when set", function()
        local InventoryModule = require("src.InventoryModule")
        local inv = InventoryModule.new()
        GachaSystem.inventory = inv
        GachaSystem.tickets.equipment = 1
        local reward = GachaSystem:rollEquipment("Weapon")
        assert.equals(1, #inv.itemSystem.inventory)
        assert.equals(reward.name, inv.itemSystem.inventory[1].name)
        GachaSystem.inventory = nil
    end)

    it("consumes crystals when no tickets", function()
        GachaSystem.tickets.skill = 0
        GachaSystem.crystals = 1
        local reward = GachaSystem:rollSkill()
        assert.is_table(reward)
        assert.equals(0, GachaSystem.crystals)
    end)

    it("returns nil without currency", function()
        GachaSystem.tickets.skill = 0
        GachaSystem.crystals = 0
        local reward = GachaSystem:rollSkill()
        assert.is_nil(reward)
    end)

    it("saves and loads state", function()
        GachaSystem.tickets.skill = 2
        GachaSystem.crystals = 5
        local saved = GachaSystem:saveData()
        GachaSystem.tickets.skill = 0
        GachaSystem.crystals = 0
        GachaSystem:loadData(saved)
        assert.equals(2, GachaSystem.tickets.skill)
        assert.equals(5, GachaSystem.crystals)
    end)

    it("adds currency via helper functions", function()
        GachaSystem.tickets.skill = 0
        GachaSystem.crystals = 0
        GachaSystem:addTickets("skill", 3)
        GachaSystem:addCrystals(2)
        assert.equals(3, GachaSystem.tickets.skill)
        assert.equals(2, GachaSystem.crystals)
    end)

    it("allows overriding rarity weights per category", function()
        local custom = {{"A", 1}}
        GachaSystem:setRarityWeights("skill", custom)
        local r = GachaSystem:rollRarity("skill")
        assert.equals("A", r)
        -- restore default for other tests
        GachaSystem:setRarityWeights("skill", {
            {"C", 80}, {"D", 25}, {"B", 5}, {"A", 1},
            {"S", 0.1}, {"SS", 0.001}, {"SSS", 1e-12},
        })
    end)

    it("rolls multiple rewards until currency runs out", function()
        GachaSystem.tickets.skill = 2
        GachaSystem.crystals = 0 -- ensure no extra currency available
        local rewards = GachaSystem:rollSkills(3)
        assert.equals(2, #rewards)
    end)
end)
