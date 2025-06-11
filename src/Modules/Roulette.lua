local Roulette = {}

local chances = {
    {Rarity = "SSS", Weight = 0.000000000001},
    {Rarity = "SS", Weight = 0.001},
    {Rarity = "S", Weight = 0.1},
    {Rarity = "A", Weight = 1},
    {Rarity = "B", Weight = 5},
    {Rarity = "C", Weight = 80},
    {Rarity = "D", Weight = 25},
}

local function chooseRarity()
    local totalWeight = 0
    for _, c in ipairs(chances) do
        totalWeight += c.Weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, c in ipairs(chances) do
        cumulative += c.Weight
        if roll <= cumulative then
            return c.Rarity
        end
    end
    return "D"
end

function Roulette:GetRandomItem(itemsByRarity)
    local rarity = chooseRarity()
    local pool = itemsByRarity[rarity]
    if not pool or #pool == 0 then
        return nil
    end
    return pool[math.random(#pool)], rarity
end

return Roulette
