local GameManager = require("../src/GameManager")

describe("GameManager", function()
    it("exposes a start function", function()
        assert.is_function(GameManager.start)
    end)

    it("exposes an update function", function()
        assert.is_function(GameManager.update)
    end)

    it("start and update do not error", function()
        assert.is_true(pcall(function() GameManager:start() end))
        assert.is_true(pcall(function() GameManager:update(0.1) end))
    end)
end)
