local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager.new(player)
    local self = setmetatable({}, PlayerManager)
    self.Player = player
    self.Level = 1
    self.Exp = 0
    self.Kills = 0
    self.Gauge = 0   -- progress for random item selection
    self.Coins = 0
    self.Ether = 0
    self.Crystals = 0
    self.CompanionShards = 0
    self.UpgradeStones = 0
    self.Tickets = 0
    self.Keys = 0
    self.LocationIndex = 1
    self.Skills = {}
    self.Companions = {}
    return self
end

local function expToNextLevel(level)
    return 100 * level
end

function PlayerManager:AddExp(amount)
    self.Exp += amount
    while self.Exp >= expToNextLevel(self.Level) do
        self.Exp -= expToNextLevel(self.Level)
        self.Level += 1
    end
end

function PlayerManager:RecordKill()
    self.Kills += 1
    self.Gauge += 1
end

function PlayerManager:ResetKills()
    self.Kills = 0
end

function PlayerManager:AddCurrency(kind, amount)
    self[kind] = (self[kind] or 0) + amount
end

function PlayerManager:SpendCurrency(kind, amount)
    if (self[kind] or 0) < amount then
        return false
    end
    self[kind] -= amount
    return true
end

function PlayerManager:AddSkill(skill)
    table.insert(self.Skills, skill)
end

function PlayerManager:AddCompanion(companion)
    table.insert(self.Companions, companion)
end

function PlayerManager:SetLocation(index)
    self.LocationIndex = index
end

function PlayerManager:GetLocation()
    return self.LocationIndex
end

return PlayerManager
