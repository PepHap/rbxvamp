local LevelSystem = require("../src/LevelSystem")

describe("LevelSystem", function()
    it("starts at level 1", function()
        assert.equals(1, LevelSystem.currentLevel)
    end)

    it("advances the level", function()
        LevelSystem.currentLevel = 1
        local newLevel = LevelSystem:advance()
        assert.equals(2, LevelSystem.currentLevel)
        assert.equals(2, newLevel)
    end)
end)
