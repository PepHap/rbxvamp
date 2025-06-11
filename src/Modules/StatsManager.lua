local StatsManager = {}
StatsManager.__index = StatsManager

local baseCosts = {
    Attack = 10,
    Health = 15,
    Defense = 10,
    Mana = 5,
}

function StatsManager.new(playerManager)
    local self = setmetatable({}, StatsManager)
    self.PlayerManager = playerManager
    self.Stats = {
        Attack = 1,
        Health = 100,
        Defense = 0,
        Mana = 0,
    }
    return self
end

function StatsManager:Upgrade(stat)
    local cost = baseCosts[stat]
    if not cost then return false end
    if not self.PlayerManager:SpendCurrency("Coins", cost) then
        local crystalCost = math.ceil(cost / 10)
        if not self.PlayerManager:SpendCurrency("Crystals", crystalCost) then
            return false
        end
    end
    self.Stats[stat] = (self.Stats[stat] or 0) + 1
    return true
end

function StatsManager:Get(stat)
    return self.Stats[stat]
end

return StatsManager
