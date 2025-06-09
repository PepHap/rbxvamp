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
end)
