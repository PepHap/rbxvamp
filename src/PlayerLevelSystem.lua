local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return ModuleUtil.requireChild(script.Parent, "PlayerLevelSystem.server")
else
    return ModuleUtil.requireChild(script.Parent, "PlayerLevelSystem.client")
end
