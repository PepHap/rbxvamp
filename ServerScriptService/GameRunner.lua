-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.

local GameManager = require(script.Parent.src.GameManager)
GameManager:start()
GameManager.systems.AutoBattle:enable()

local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute then
        player:SetAttribute("SaveData", data)
    end
    -- Start automatic saving for this player's data
    GameManager.autoSaveSystem:start(
        GameManager.saveSystem,
        player.UserId,
        function()
            if player.GetAttribute then
                return player:GetAttribute("SaveData")
            end
        end
    )
end)

Players.PlayerRemoving:Connect(function(player)
    local data
    if player.GetAttribute then
        data = player:GetAttribute("SaveData")
    end
    if data then
        GameManager:savePlayerData(player.UserId, data)
    end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

