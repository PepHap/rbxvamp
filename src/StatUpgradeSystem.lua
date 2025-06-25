local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

if not mod then
    warn("StatUpgradeSystem child module missing; using fallback implementation")
    mod = {}
    function mod:getStat(_)
        return 0
    end
    function mod:loadData(_) end
    function mod:saveData() return {} end
end

return mod
