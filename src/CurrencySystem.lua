-- CurrencySystem.lua
-- Simple module for tracking multiple currencies

local CurrencySystem = {}

local RunService = game:GetService("RunService")
local NetworkSystem
if RunService:IsServer() then
    NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
end
local LoggingSystem
if RunService and RunService.IsServer and RunService:IsServer() then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    LoggingSystem = require(serverFolder:WaitForChild("LoggingSystem"))
end

-- Table of balances by currency key
CurrencySystem.balances = {}

---Adds currency to the given type.
-- @param kind string currency identifier
-- @param amount number amount to add
function CurrencySystem:add(kind, amount)
    local n = tonumber(amount) or 0
    if RunService:IsServer() then
        local serverFolder = script.Parent.Parent:FindFirstChild("server")
        if serverFolder then
            local systems = serverFolder:FindFirstChild("systems")
            if systems then
                local AntiCheatSystem = require(systems:WaitForChild("AntiCheatSystem"))
                if AntiCheatSystem.recordCurrency then
                    AntiCheatSystem:recordCurrency(nil, n)
                end
            end
        end
    end
    if RunService:IsServer() and LoggingSystem and LoggingSystem.logCurrency then
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
            if LoggingSystem and LoggingSystem.logCurrency then
                LoggingSystem:logCurrency(nil, kind, -amount)
            end
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
            if LoggingSystem and LoggingSystem.logCurrency then
                LoggingSystem:logCurrency(nil, k, v)
            end
            NetworkSystem:fireAllClients("CurrencyUpdate", k, v)
        end
    end
end

-- Strip server-only methods when running on the client
if RunService:IsClient() then
    local serverOnly = { add = true, spend = true, saveData = true }
    for name in pairs(serverOnly) do
        CurrencySystem[name] = nil
    end
end

return CurrencySystem
