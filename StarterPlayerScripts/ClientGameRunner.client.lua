-- ClientGameRunner.lua
-- Initializes client-only gameplay systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local src = ReplicatedStorage:WaitForChild("src")

-- Handle player input locally so UI modules can toggle windows
local PlayerInputSystem = require(src:WaitForChild("PlayerInputSystem"))
PlayerInputSystem.useRobloxObjects = true

-- Load saved data from the server and apply it to the local GameManager
local GameManager = require(src:WaitForChild("GameManager"))

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
    if type(PlayerInputSystem.update) == "function" then
        PlayerInputSystem:update(dt)
    end
end)
