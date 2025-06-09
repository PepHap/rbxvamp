local PlayerLevelSystem = require("src.PlayerLevelSystem")

describe("PlayerLevelSystem", function()
    it("starts at level 1 with zero exp", function()
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 0
        assert.equals(1, PlayerLevelSystem.level)
        assert.equals(0, PlayerLevelSystem.exp)
    end)

    it("adds experience without leveling when below threshold", function()
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 0
        PlayerLevelSystem.nextExp = 100
        PlayerLevelSystem:addExperience(50)
        assert.equals(50, PlayerLevelSystem.exp)
        assert.equals(1, PlayerLevelSystem.level)
    end)

    it("levels up when reaching threshold", function()
        PlayerLevelSystem.level = 1
        PlayerLevelSystem.exp = 90
        PlayerLevelSystem.nextExp = 100
        PlayerLevelSystem:addExperience(20)
        assert.equals(2, PlayerLevelSystem.level)
        assert.equals(10, PlayerLevelSystem.exp)
    end)

    it("unlocks content on milestone levels", function()
        PlayerLevelSystem.level = 4
        PlayerLevelSystem.exp = 90
        PlayerLevelSystem.nextExp = 100
        PlayerLevelSystem.unlocked = {}
        PlayerLevelSystem:addExperience(20)
        assert.is_true(#PlayerLevelSystem.unlocked > 0)
    end)
end)
