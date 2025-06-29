-- UILoader.client.lua
-- Initializes UI modules client-side using a LocalScript so
-- each player gets their own interface rendered locally.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")

local QuestUISystem = require(src:WaitForChild("QuestUISystem"))
local RewardGaugeUISystem = require(src:WaitForChild("RewardGaugeUISystem"))
local GameManager = require(src:WaitForChild("ClientGameManager"))
local GuiXmlLoader = require(src:WaitForChild("GuiXmlLoader"))
local guiData = require(src:WaitForChild("gui_data"))
local UIBridge = require(src:WaitForChild("UIBridge"))

-- load the interface defined in gui.rbxmx
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("InventoryUI")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    for _, item in ipairs(guiData) do
        if not (item.Properties and item.Properties.Name == "Hud") then
            GuiXmlLoader.createFromTable(item, screenGui)
        end
    end
    screenGui.Parent = playerGui
end
UIBridge.init(screenGui)

local modules = {
    QuestUISystem,
    RewardGaugeUISystem,
}

for _, mod in ipairs(modules) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
        if type(mod.start) == "function" then
            if mod == QuestUISystem then
                mod:start(GameManager.systems.Quest)
            else
                mod:start()
            end
        end
    end
end

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    for _, mod in ipairs(modules) do
        if type(mod.update) == "function" then
            mod:update(dt)
        end
    end
end)

