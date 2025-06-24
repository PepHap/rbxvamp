local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return ModuleUtil.requireChild(script.Parent, "GachaSystem.server", 10)
else
    return ModuleUtil.requireChild(script.Parent, "ClientGachaSystem", 10)
end
