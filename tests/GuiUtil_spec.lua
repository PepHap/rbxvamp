local GuiUtil = require("src.GuiUtil")

describe("GuiUtil", function()
    it("adds hoverColor on connect", function()
        local btn = {ClassName = "TextButton"}
        GuiUtil.connectButton(btn, function() end)
        assert.is_not_nil(btn.hoverColor)
    end)
end)
