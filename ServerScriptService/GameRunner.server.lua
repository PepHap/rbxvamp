-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.

local GameManager = require(script.Parent.src.GameManager)

-- Enable Roblox object creation for modules that support it so the
-- user can actually see models and interfaces when running the game
local modulesWithUI = {
    require(script.Parent.src.HudSystem),
    require(script.Parent.src.InventoryUISystem),
    require(script.Parent.src.SkillUISystem),
    require(script.Parent.src.CompanionUISystem),
    require(script.Parent.src.StatUpgradeUISystem),
    require(script.Parent.src.QuestUISystem),
    require(script.Parent.src.UISystem),
    require(script.Parent.src.PlayerSystem),
    require(script.Parent.src.PlayerInputSystem),
    require(script.Parent.src.EnemySystem),
    require(script.Parent.src.DataPersistenceSystem),
}
for _, mod in ipairs(modulesWithUI) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
    end
end

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

