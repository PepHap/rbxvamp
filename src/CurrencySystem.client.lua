local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("CurrencySystem.client should only be required on the client", 2)
end

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

local ClientCurrencySystem = {
    balances = CurrencySystem.balances
}

function ClientCurrencySystem:get(kind)
    return CurrencySystem:get(kind)
end

function ClientCurrencySystem:loadData(data)
    CurrencySystem:loadData(data)
end

return ClientCurrencySystem
