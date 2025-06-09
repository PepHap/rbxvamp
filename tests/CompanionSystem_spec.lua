local CompanionSystem = require("../src/CompanionSystem")

describe("CompanionSystem", function()
    it("can add a companion", function()
        CompanionSystem.companions = {}
        CompanionSystem:add("Ghost")
        assert.are.same({"Ghost"}, CompanionSystem.companions)
    end)
end)
