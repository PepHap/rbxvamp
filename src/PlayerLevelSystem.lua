local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")
local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

if not mod then
    warn("PlayerLevelSystem child module missing; using fallback implementation")
    mod = { level = 1, exp = 0 }
    function mod:addExp(amount)
        amount = tonumber(amount) or 0
        self.exp += amount
    end
    function mod:saveData()
        return { level = self.level, exp = self.exp }
    end
    function mod:loadData(data)
        if type(data) ~= "table" then return end
        if type(data.level) == "number" then self.level = data.level end
        if type(data.exp) == "number" then self.exp = data.exp end
    end
end

return mod
