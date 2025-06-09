local GameManager = require("src.GameManager")

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

    it("registers and starts added systems", function()
        local started = 0
        local mockSystem = {
            start = function()
                started = started + 1
            end
        }

        GameManager:addSystem("Mock", mockSystem)

        -- Verify the system tables were updated
        assert.equals(mockSystem, GameManager.systems.Mock)
        assert.equals("Mock", GameManager.order[#GameManager.order])

        GameManager:start()
        assert.equals(1, started)
    end)
end)
