local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return ModuleUtil.requireChild(script.Parent, "StatUpgradeSystem.server", 10)
else
    return ModuleUtil.requireChild(script.Parent, "StatUpgradeSystem.client", 10)
end
