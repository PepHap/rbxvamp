-- UILoader.client.lua
-- Initializes UI modules client-side using a LocalScript so
-- each player gets their own interface rendered locally.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")

-- Legacy UI modules have been removed. Only gui.rbxmx is loaded now.
-- create the interface from the generated Lua builder
local GeneratedGui = require(src:WaitForChild("GeneratedGui"))
local UIBridge = require(src:WaitForChild("UIBridge"))

-- load the interface defined in gui.rbxmx
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("InventoryUI")
if not screenGui then
    screenGui = GeneratedGui(playerGui)
end
UIBridge.init(screenGui)

-- No additional UI modules are initialized.

