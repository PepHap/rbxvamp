local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local RunService = game:GetService("RunService")

local mod
if RunService:IsServer() then
    mod = ModuleUtil.requireChild(script, "server", 10)
else
    mod = ModuleUtil.requireChild(script, "client", 10)
end

-- Fallback to a minimal implementation if the child module is missing
if not mod then
    warn("CurrencySystem child module missing; using fallback implementation")
    mod = {
        balances = {},
        get = function(self, kind)
            return self.balances[kind] or 0
        end,
        loadData = function(self, data)
            self.balances = {}
            if type(data) ~= "table" then return end
            for k, v in pairs(data) do
                self.balances[k] = v
            end
        end,
    }
end

return mod
