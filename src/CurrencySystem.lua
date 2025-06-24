local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("CurrencySystem.server"))
else
    return require(script.Parent:WaitForChild("CurrencySystem.client"))
end
