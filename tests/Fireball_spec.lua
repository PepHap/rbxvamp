local Fireball = require("src.skills.Fireball")

describe("Fireball skill module", function()
    it("records a cast in non-Roblox mode", function()
        Fireball.useRobloxObjects = false
        Fireball.lastCast = nil
        Fireball.cast({}, {level = 1}, {})
        assert.is_table(Fireball.lastCast)
        assert.equals(1, Fireball.lastCast.level)
    end)

    it("applies level bonuses", function()
        local skill = {cooldown = 3, level = 10}
        Fireball.applyLevel(skill)
        assert.equals(2, skill.cooldown)
        assert.equals(1, skill.extraProjectiles)
    end)
end)
