-- CurrencySystem.lua
-- Simple module for tracking multiple currencies

local CurrencySystem = {}

-- Table of balances by currency key
CurrencySystem.balances = {}

---Adds currency to the given type.
-- @param kind string currency identifier
-- @param amount number amount to add
function CurrencySystem:add(kind, amount)
    self.balances[kind] = (self.balances[kind] or 0) + amount
end

---Retrieves the current balance for a currency.
-- @param kind string currency identifier
-- @return number
function CurrencySystem:get(kind)
    return self.balances[kind] or 0
end

---Attempts to spend the requested currency amount.
-- @param kind string currency identifier
-- @param amount number amount to deduct
-- @return boolean true when the spend succeeds
function CurrencySystem:spend(kind, amount)
    if self:get(kind) >= amount then
        self.balances[kind] = self.balances[kind] - amount
        return true
    end
    return false
end

return CurrencySystem
