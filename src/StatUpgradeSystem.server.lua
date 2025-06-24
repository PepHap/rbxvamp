-- StatUpgradeSystem.lua
-- Manages basic player stats and allows upgrading them using CurrencySystem.

local StatUpgradeSystem = {}

-- Table of stat data keyed by stat name.
-- Each entry stores a base value and current level.
StatUpgradeSystem.stats = {}

---Multiplier applied when calculating upgrade costs. Each level costs
--  ``level * costFactor`` of the chosen currency. Adjust this value to
--  tune overall stat progression difficulty.
StatUpgradeSystem.costFactor = 1

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local RunService = game:GetService("RunService")

---Adds a new stat with the provided base value.
-- @param name string name of the stat
-- @param baseValue number starting value for the stat
function StatUpgradeSystem:addStat(name, baseValue)
    assert(name, "stat name required")
    assert(type(baseValue) == "number", "baseValue must be number")
    self.stats[name] = {level = 1, base = baseValue}
end

---Calculates the currency cost required for upgrading ``amount`` levels of the
--  stat.
-- @param name string stat name
-- @param amount number how many levels to add
-- @return number cost in currency
function StatUpgradeSystem:getUpgradeCost(name, amount)
    local stat = self.stats[name]
    local n = tonumber(amount) or 1
    if not stat or n <= 0 then
        return 0
    end
    return (stat.level or 1) * n * (self.costFactor or 1)
end

---Upgrades a stat by spending currency.
-- The cost scales with the stat level using `getUpgradeCost`.
-- @param name string stat name
-- @param amount number number of levels to add
-- @param currency string currency key used for payment
-- @return boolean true when the upgrade succeeds
function StatUpgradeSystem:upgradeStat(name, amount, currency)
    local stat = self.stats[name]
    local n = tonumber(amount)
    if not stat or not n or n <= 0 then
        return false
    end
    local cost = StatUpgradeSystem:getUpgradeCost(name, n)
    if not CurrencySystem:spend(currency, cost) then
        return false
    end
    stat.level = stat.level + n
    return true
end

---Upgrades a stat using ``currency`` or crystals when lacking funds.
--  This behaves similar to ``upgradeStat`` but will attempt to purchase the
--  required currency through ``CrystalExchangeSystem`` when the current balance
--  is insufficient. The function returns ``true`` only when the upgrade and any
--  currency exchange succeed.
--  @param name string stat name
--  @param amount number levels to add
--  @param currency string currency key used for payment
--  @return boolean success
function StatUpgradeSystem:upgradeStatWithFallback(name, amount, currency)
    local stat = self.stats[name]
    local n = tonumber(amount)
    if not stat or not n or n <= 0 then
        return false
    end
    local cost = StatUpgradeSystem:getUpgradeCost(name, n)
    if not CurrencySystem:spend(currency, cost) then
        local CrystalExchangeSystem = require(script.Parent:WaitForChild("CrystalExchangeSystem"))
        if not CrystalExchangeSystem:buyCurrency(currency, cost) then
            return false
        end
        if not CurrencySystem:spend(currency, cost) then
            return false
        end
    end
    stat.level = stat.level + n
    return true
end

---Serializes the stat table for persistence.
-- @return table serialized stats
function StatUpgradeSystem:saveData()
    local data = {}
    for name, info in pairs(self.stats) do
        data[name] = {level = info.level, base = info.base}
    end
    return data
end

---Loads stat levels from a saved table.
-- Unknown stats are added automatically.
-- @param data table stats previously produced by ``saveData``
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

