-- ClientGameRunner.lua
-- Initializes client-only gameplay systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local src = ReplicatedStorage:WaitForChild("src")
local ModuleUtil = require(src:WaitForChild("ModuleUtil"))

-- Handle player input locally so UI modules can toggle windows
local PlayerInputSystem = ModuleUtil.requireChild(src, "PlayerInputSystem") or {}
PlayerInputSystem.useRobloxObjects = true

-- Start core gameplay systems on the client so UI modules
-- have initialized data like quests and inventory.
local GameManager = ModuleUtil.requireChild(src, "ClientGameManager") or {}
if type(GameManager.start) == "function" then
    GameManager:start()
end
-- Auto battle runs exclusively on the server

-- Load saved data from the server and apply it to the local GameManager

local function applyClientData()
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
            if GameManager.applyClientData then
                GameManager:applyClientData(data)
            end
        end
    end
end

applyClientData()

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
