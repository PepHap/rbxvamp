-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.


if not game:IsLoaded() then
    game.Loaded:Wait()
end
local src = script.Parent:WaitForChild("src")
local server = script.Parent:WaitForChild("server")
local GameManager = require(server:WaitForChild("ServerGameManager"))

-- Ensure asset modules are replicated to clients
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local assets = ReplicatedStorage:FindFirstChild("assets")
if not assets then
    local ssAssets = ServerStorage:FindFirstChild("assets")
    if ssAssets then
        assets = ssAssets:Clone()
        assets.Parent = ReplicatedStorage
    end
end

local ADMIN_IDS = {game.CreatorId}

-- Enable Roblox object creation for modules that support it so the
-- user can actually see models and interfaces when running the game
-- Only non-UI modules should run on the server to avoid
-- duplicating interface elements for each client.
local modulesWithUI = {
    require(server:WaitForChild("ServerPlayerSystem")),
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
GameManager:setAdminIds(ADMIN_IDS)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

Players.PlayerAdded:Connect(function(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute and HttpService then
        local encoded = HttpService:JSONEncode(data)
        player:SetAttribute("SaveData", encoded)
    end
    -- Start automatic saving for this player
    GameManager:startAutoSave(player.UserId)
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
    GameManager:forceAutoSave()
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

