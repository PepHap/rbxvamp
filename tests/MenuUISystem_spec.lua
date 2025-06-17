local MenuUISystem = require("src.MenuUISystem")

describe("MenuUISystem", function()
    before_each(function()
        MenuUISystem.gui = nil
        MenuUISystem.window = nil
        MenuUISystem.contentFrame = nil
        MenuUISystem.tabs = {}
        MenuUISystem.tabButtons = {}
        MenuUISystem.currentTab = 1
        MenuUISystem.visible = false
    end)

    it("adds and switches tabs", function()
        local stub = {start=function() end, setVisible=function() end}
        MenuUISystem:addTab("A", stub)
        MenuUISystem:addTab("B", stub)
        MenuUISystem:showTab(2)
        assert.equals(2, MenuUISystem.currentTab)
    end)
end)
