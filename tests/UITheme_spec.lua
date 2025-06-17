local Theme = require("src.UITheme")

describe("UITheme", function()
    it("styles basic tables", function()
        local btn = {ClassName="TextButton", TextColor3=nil}
        Theme.styleButton(btn)
        assert.is_not_nil(btn.TextColor3)
        assert.equals(Theme.cornerRadius, btn.cornerRadius)
    end)

    it("applies corner radius to windows", function()
        local win = {ClassName="Frame"}
        Theme.styleWindow(win)
        assert.equals(Theme.cornerRadius, win.cornerRadius)
    end)
end)
