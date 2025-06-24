local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return require(script.Parent:WaitForChild("InventoryModule.server"))
else
    return require(script.Parent:WaitForChild("InventoryModule.client"))
end
