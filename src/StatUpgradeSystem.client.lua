local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("StatUpgradeSystem.client should only be required on the client", 2)
end

local StatUpgradeSystem = {}
StatUpgradeSystem.stats = {}
StatUpgradeSystem.costFactor = 1

function StatUpgradeSystem:addStat(name, baseValue)
    assert(name, "stat name required")
    assert(type(baseValue) == "number", "baseValue must be number")
    self.stats[name] = {level = 1, base = baseValue}
end

function StatUpgradeSystem:getUpgradeCost(name, amount)
    local stat = self.stats[name]
    local n = tonumber(amount) or 1
    if not stat or n <= 0 then
        return 0
    end
    return (stat.level or 1) * n * (self.costFactor or 1)
end

function StatUpgradeSystem:saveData()
    local data = {}
    for name, info in pairs(self.stats) do
        data[name] = {level = info.level, base = info.base}
    end
    return data
end

function StatUpgradeSystem:loadData(data)
    if type(data) ~= "table" then return end
    for name, info in pairs(data) do
        local stat = self.stats[name]
        if stat then
            if type(info.level) == "number" then
                stat.level = info.level
            end
            if type(info.base) == "number" then
                stat.base = info.base
            end
        else
            self.stats[name] = {
                level = info.level or 1,
                base = info.base or 0,
            }
        end
    end
end

return StatUpgradeSystem
