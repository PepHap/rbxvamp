local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("CurrencySystem client module should only be required on the client", 2)
end

local CurrencySystem = {}
CurrencySystem.balances = {}

function CurrencySystem:get(kind)
    return self.balances[kind] or 0
end

function CurrencySystem:loadData(data)
    self.balances = {}
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        self.balances[k] = v
    end
end

return CurrencySystem
