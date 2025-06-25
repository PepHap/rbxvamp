local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

if not mod then
    warn("AutoBattleSystem child module missing; using fallback implementation")
    mod = { enabled = false }
end

return mod
