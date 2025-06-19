-- ClientGameRunner.lua
-- Initializes client-only gameplay systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")

-- Handle player input locally so UI modules can toggle windows
local PlayerInputSystem = require(src:WaitForChild("PlayerInputSystem"))
PlayerInputSystem.useRobloxObjects = true

-- Start core gameplay systems on the client so UI modules
-- have initialized data like quests and inventory.
local GameManager = require(src:WaitForChild("GameManager"))
GameManager:start()
if GameManager.systems and GameManager.systems.AutoBattle then
    GameManager.systems.AutoBattle:enable()
end

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
