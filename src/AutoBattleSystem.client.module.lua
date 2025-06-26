local AutoBattleSystem = {enabled = false}

local RunService = game:GetService("RunService")
if RunService:IsClient() then
    local ok, NetworkSystem = pcall(function()
        return require(script.Parent:WaitForChild("NetworkSystem"))
    end)
    if ok and NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("AutoBattleToggle", function(state)
            AutoBattleSystem.enabled = not not state
        end)
    end
end

return AutoBattleSystem
