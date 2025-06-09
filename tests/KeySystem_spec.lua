local KeySystem = require("src.KeySystem")

describe("KeySystem", function()
    before_each(function()
        KeySystem.keys = {}
    end)

    it("adds keys for a type", function()
        KeySystem:addKey("arena", 3)
        assert.equals(3, KeySystem:getCount("arena"))
    end)

    it("uses keys when available", function()
        KeySystem:addKey("skill", 1)
        local ok = KeySystem:useKey("skill")
        assert.is_true(ok)
        assert.equals(0, KeySystem:getCount("skill"))
    end)

    it("fails to use missing keys", function()
        local ok = KeySystem:useKey("arena")
        assert.is_false(ok)
    end)
end)
