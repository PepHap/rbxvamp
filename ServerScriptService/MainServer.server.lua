local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")


if not game:IsLoaded() then
    game.Loaded:Wait()
end

local src = script.Parent:WaitForChild("src")
local GameManager = require(src:WaitForChild("GameManager"))

local function onPlayerAdded(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute and HttpService then
        local encoded = HttpService:JSONEncode(data)
        player:SetAttribute("SaveData", encoded)
    end
end

local function onPlayerRemoving(player)
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
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
