local MenuUISystem = require("src.MenuUISystem")
local InventoryUISystem = require("src.InventoryUISystem")
local SkillUISystem = require("src.SkillUISystem")

describe("MenuUISystem", function()
    before_each(function()
        MenuUISystem.gui = nil
        MenuUISystem.window = nil
        MenuUISystem.contentFrame = nil
        MenuUISystem.tabs = {}
        MenuUISystem.tabButtons = {}
        MenuUISystem.currentTab = 1
        MenuUISystem.visible = false
        InventoryUISystem.gui = nil
        InventoryUISystem.window = nil
        InventoryUISystem.visible = false
        SkillUISystem.gui = nil
        SkillUISystem.window = nil
        SkillUISystem.visible = false
    end)

    it("starts and shows inventory tab", function()
        MenuUISystem:start()
        assert.is_table(MenuUISystem.gui)
        assert.is_true(InventoryUISystem.visible)
        assert.is_false(SkillUISystem.visible)
    end)

    it("switches between tabs", function()
        MenuUISystem:start()
        MenuUISystem:showTab(2)
        assert.is_true(SkillUISystem.visible)
        assert.is_false(InventoryUISystem.visible)
    end)
end)
