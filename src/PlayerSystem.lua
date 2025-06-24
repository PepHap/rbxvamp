local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return ModuleUtil.requireChild(script.Parent, "PlayerSystem.server", 10)
else
    return ModuleUtil.requireChild(script.Parent, "PlayerSystem.client", 10)
end
