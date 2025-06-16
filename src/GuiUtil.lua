local GuiUtil = {}

function GuiUtil.getPlayerGui()
    if not game or type(game.GetService) ~= "function" then
        return nil
    end
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok or not players then
        return nil
    end
    if players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
        return players.LocalPlayer.PlayerGui
    end
    local list = players:GetPlayers()
    if list and #list > 0 then
        local p = list[1]
        if p then
            return p:FindFirstChild("PlayerGui") or (p.WaitForChild and p:WaitForChild("PlayerGui", 5))
        end
    end
    return nil
end

return GuiUtil
