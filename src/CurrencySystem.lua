-- CurrencySystem.lua
-- Simple module for tracking multiple currencies

local CurrencySystem = {}

local RunService = game:GetService("RunService")
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))

-- Table of balances by currency key
CurrencySystem.balances = {}

---Adds currency to the given type.
-- @param kind string currency identifier
-- @param amount number amount to add
function CurrencySystem:add(kind, amount)
    local n = tonumber(amount) or 0
    local AntiCheatSystem = require(script.Parent:WaitForChild("AntiCheatSystem"))
    AntiCheatSystem:recordCurrency(nil, n)
    if RunService:IsServer() then
        LoggingSystem:logCurrency(nil, kind, n)
    end
    self.balances[kind] = (self.balances[kind] or 0) + n
    if RunService:IsServer() then
        NetworkSystem:fireAllClients("CurrencyUpdate", kind, self.balances[kind])
    end
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
        if RunService:IsServer() then
            LoggingSystem:logCurrency(nil, kind, -amount)
            NetworkSystem:fireAllClients("CurrencyUpdate", kind, self.balances[kind])
        end
        return true
    end
    return false
end

---Serializes all currency balances.
-- @return table balances table
function CurrencySystem:saveData()
    local copy = {}
    for k, v in pairs(self.balances) do
        copy[k] = v
    end
    return copy
end

---Loads balances from the provided table.
-- @param data table balance table
function CurrencySystem:loadData(data)
    self.balances = {}
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        self.balances[k] = v
        if RunService:IsServer() then
            LoggingSystem:logCurrency(nil, k, v)
            NetworkSystem:fireAllClients("CurrencyUpdate", k, v)
        end
    end
end

return CurrencySystem
