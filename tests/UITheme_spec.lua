local Theme = require("src.UITheme")

describe("UITheme", function()
    it("styles basic tables", function()
        local btn = {ClassName="TextButton", TextColor3=nil}
        Theme.styleButton(btn)
        assert.is_not_nil(btn.TextColor3)
    end)
end)
