-- ClientGameRunner.lua
-- Starts GameManager client-side so UI modules become visible.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")
local GameManager = require(src.GameManager)

-- Enable Roblox objects for modules with UI when running in Studio
-- Enable Roblox objects on all systems that support it so that GUIs and models
-- appear client-side when running in Studio.
GameManager:enableRobloxUI()

GameManager:start()
GameManager.systems.AutoBattle:enable()

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    GameManager:update(dt)
end)
