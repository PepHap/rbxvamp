local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return ModuleUtil.requireChild(script.Parent, "PlayerLevelSystem.server", 10)
else
    return ModuleUtil.requireChild(script.Parent, "PlayerLevelSystem.client", 10)
end
