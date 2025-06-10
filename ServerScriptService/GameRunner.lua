-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.

local GameManager = require(script.Parent.src.GameManager)
GameManager:start()
GameManager.systems.AutoBattle:enable()

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

