local AutoSaveSystem = require("../src/AutoSaveSystem")

local fakeSave = {
    saved = {},
    save = function(self, id, data)
        self.saved[id] = data
    end
}

describe("AutoSaveSystem", function()
    before_each(function()
        fakeSave.saved = {}
        AutoSaveSystem.interval = 1
        AutoSaveSystem.timer = 0
    end)

    it("saves after interval elapses", function()
        AutoSaveSystem:start(fakeSave, "player", function() return {x=1} end)
        AutoSaveSystem:update(0.5)
        assert.is_nil(fakeSave.saved.player)
        AutoSaveSystem:update(0.6)
        assert.same({x=1}, fakeSave.saved.player)
    end)

    it("forces save immediately", function()
        AutoSaveSystem:start(fakeSave, "p", function() return {y=2} end)
        AutoSaveSystem:forceSave()
        assert.same({y=2}, fakeSave.saved.p)
    end)
end)

