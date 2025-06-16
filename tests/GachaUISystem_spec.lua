local GachaUISystem = require("src.GachaUISystem")

describe("GachaUISystem", function()
    before_each(function()
        GachaUISystem.gui = nil
        GachaUISystem.visible = false
        GachaUISystem.gameManager = {
            rollSkill = function() return {name = "Fireball", rarity = "A"} end,
            rollCompanion = function() return {name = "Wolf", rarity = "B"} end,
            rollEquipment = function() return {name = "Sword", rarity = "C"} end,
        }
    end)

    it("creates buttons and toggles visibility", function()
        GachaUISystem:start(GachaUISystem.gameManager)
        assert.is_table(GachaUISystem.gui)
        assert.equals("ScreenGui", GachaUISystem.gui.ClassName)
        assert.equals("TextButton", GachaUISystem.skillButton.ClassName)
        GachaUISystem:toggle()
        assert.is_true(GachaUISystem.visible)
    end)

    it("shows roll results", function()
        GachaUISystem:start(GachaUISystem.gameManager)
        GachaUISystem:rollSkill()
        assert.is_truthy(string.find(GachaUISystem.resultLabel.Text, "Fireball"))
        GachaUISystem:rollCompanion()
        assert.is_truthy(string.find(GachaUISystem.resultLabel.Text, "Wolf"))
        GachaUISystem:rollEquipment("Weapon")
        assert.is_truthy(string.find(GachaUISystem.resultLabel.Text, "Sword"))
    end)
end)
