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

