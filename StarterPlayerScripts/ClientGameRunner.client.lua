-- ClientGameRunner.lua
-- Initializes client-only gameplay systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")

-- Handle player input locally so UI modules can toggle windows
local PlayerInputSystem = require(src:WaitForChild("PlayerInputSystem"))
PlayerInputSystem.useRobloxObjects = true

if type(PlayerInputSystem.start) == "function" then
    PlayerInputSystem:start()
end

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    if type(PlayerInputSystem.update) == "function" then
        PlayerInputSystem:update(dt)
    end
end)
