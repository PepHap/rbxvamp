local items = require("assets.items")
local skills = require("assets.skills")

describe("Assets", function()
    it("loads item templates", function()
        assert.is_table(items.Hat)
    end)

    it("loads skill templates", function()
        assert.is_string(skills[1].name)
        assert.is_string(skills[1].rarity)
    end)
end)
