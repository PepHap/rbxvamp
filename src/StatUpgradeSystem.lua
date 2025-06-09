-- StatUpgradeSystem.lua
-- Manages basic player stats and allows upgrading them using CurrencySystem.

local StatUpgradeSystem = {}

-- Table of stat data keyed by stat name.
-- Each entry stores a base value and current level.
StatUpgradeSystem.stats = {}

local CurrencySystem = require("src.CurrencySystem")

---Adds a new stat with the provided base value.
-- @param name string name of the stat
-- @param baseValue number starting value for the stat
function StatUpgradeSystem:addStat(name, baseValue)
    assert(name, "stat name required")
    assert(type(baseValue) == "number", "baseValue must be number")
    self.stats[name] = {level = 1, base = baseValue}
end

---Upgrades a stat by spending currency.
-- Cost is equal to the amount of levels being added.
-- @param name string stat name
-- @param amount number number of levels to add
-- @param currency string currency key used for payment
-- @return boolean true when the upgrade succeeds
function StatUpgradeSystem:upgradeStat(name, amount, currency)
    local stat = self.stats[name]
    if not stat or amount <= 0 then
        return false
    end
    if not CurrencySystem:spend(currency, amount) then
        return false
    end
    stat.level = stat.level + amount
    return true
end

return StatUpgradeSystem

