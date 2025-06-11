local Roulette = require(script.Parent.Roulette)

local CompanionManager = {}
CompanionManager.__index = CompanionManager

local companionsByRarity = {
    SSS = {"Phoenix"},
    SS = {"Ancient Dragon"},
    S = {"War Golem"},
    A = {"Battle Wolf"},
    B = {"Fairy", "Goblin"},
    C = {"Sprite", "Wolf"},
    D = {"Cat"},
}

function CompanionManager.new(playerManager)
    local self = setmetatable({}, CompanionManager)
    self.PlayerManager = playerManager
    self.Companions = {}
    return self
end

function CompanionManager:RollCompanion()
    if not self.PlayerManager:SpendCurrency("Tickets", 1) then
        return nil
    end
    local companion, rarity = Roulette:GetRandomItem(companionsByRarity)
    if companion then
        table.insert(self.Companions, {Name = companion, Rarity = rarity, Level = 1})
    end
    return companion, rarity
end

function CompanionManager:UpgradeCompanion(name, cost)
    if not self.PlayerManager:SpendCurrency("CompanionShards", cost) then
        return false
    end
    for _, comp in ipairs(self.Companions) do
        if comp.Name == name then
            comp.Level += 1
            return true
        end
    end
    return false
end

return CompanionManager
