local AdminConsole = require("src.AdminConsoleSystem")

describe("AdminConsoleSystem", function()
    before_each(function()
        AdminConsole.gui = nil
        AdminConsole.visible = false
        AdminConsole.adminIds = {1}
    end)

    it("creates gui and toggles visibility", function()
        AdminConsole:start(nil, {1})
        assert.is_table(AdminConsole.gui)
        AdminConsole:toggle()
        assert.is_true(AdminConsole.visible)
    end)

    it("executes commands", function()
        AdminConsole:start(nil, {1})
        local result = AdminConsole:runCommand("test")
        assert.is_truthy(string.find(result, "Executed"))
    end)
end)
