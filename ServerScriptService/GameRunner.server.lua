-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.


local src = script.Parent:WaitForChild("src")
local GameManager = require(src:WaitForChild("GameManager"))

-- Enable Roblox object creation for modules that support it so the
-- user can actually see models and interfaces when running the game
-- Only non-UI modules should run on the server to avoid
-- duplicating interface elements for each client.
local modulesWithUI = {
    require(src:WaitForChild("PlayerSystem")),
    require(src:WaitForChild("PlayerInputSystem")),
    require(src:WaitForChild("EnemySystem")),
    require(src:WaitForChild("DataPersistenceSystem")),
}
for _, mod in ipairs(modulesWithUI) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
    end
end

GameManager:start()
GameManager.systems.AutoBattle:enable()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

Players.PlayerAdded:Connect(function(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute and HttpService then
        local encoded = HttpService:JSONEncode(data)
        player:SetAttribute("SaveData", encoded)
    end
    -- Start automatic saving for this player's data
    GameManager.autoSaveSystem:start(
        GameManager.saveSystem,
        player.UserId,
        function()
            if player.GetAttribute and HttpService then
                local json = player:GetAttribute("SaveData")
                if json then
                    local success, decoded = pcall(function()
                        return HttpService:JSONDecode(json)
                    end)
                    if success then
                        return decoded
                    end
                end
            end
        end
    )
end)

Players.PlayerRemoving:Connect(function(player)
    local json
    if player.GetAttribute then
        json = player:GetAttribute("SaveData")
    end
    if json and HttpService then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if success then
            GameManager:savePlayerData(player.UserId, decoded)
        end
    end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

