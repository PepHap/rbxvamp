-- ClientGameRunner.lua
-- Initializes client-only gameplay systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local src = ReplicatedStorage:WaitForChild("src")

-- Handle player input locally so UI modules can toggle windows
local PlayerInputSystem = require(src:WaitForChild("PlayerInputSystem"))
PlayerInputSystem.useRobloxObjects = true

-- Start core gameplay systems on the client so UI modules
-- have initialized data like quests and inventory.
local GameManager = require(src:WaitForChild("ClientGameManager"))
GameManager:start()
if GameManager.systems and GameManager.systems.AutoBattle then
    GameManager.systems.AutoBattle:enable()
end

-- Load saved data from the server and apply it to the local GameManager

local function applySaveData()
    local player = Players.LocalPlayer
    if not player then return end
    local json = player:GetAttribute("SaveData")
    if not json then
        player:GetAttributeChangedSignal("SaveData"):Wait()
        json = player:GetAttribute("SaveData")
    end
    if json and HttpService then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if ok then
            GameManager:applySaveData(data)
        end
    end
end

applySaveData()

if type(PlayerInputSystem.start) == "function" then
    PlayerInputSystem:start()
end

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    -- Update main game systems client-side
    if type(GameManager.update) == "function" then
        GameManager:update(dt)
    end
    if type(PlayerInputSystem.update) == "function" then
        PlayerInputSystem:update(dt)
    end
end)
