local assets = game:GetService("ReplicatedStorage"):WaitForChild("assets")
local items = require(assets:WaitForChild("items"))
local skills = require(assets:WaitForChild("skills"))
local trees = require(assets:WaitForChild("skill_trees"))

describe("Assets", function()
    it("loads item templates", function()
        assert.is_table(items.Hat)
    end)

    it("loads skill templates", function()
        assert.is_string(skills[1].name)
        assert.is_string(skills[1].rarity)
    end)

    it("loads skill trees", function()
        assert.is_table(trees.Fireball)
    end)
end)
