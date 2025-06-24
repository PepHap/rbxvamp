local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

if RunService:IsServer() then
    return ModuleUtil.requireChild(script, "server", 10)
else
    return ModuleUtil.requireChild(script, "client", 10)
end

