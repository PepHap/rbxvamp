-- UILoader.client.lua
-- Initializes UI modules client-side using a LocalScript so
-- each player gets their own interface rendered locally.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")

local HudSystem = require(src:WaitForChild("HudSystem"))
local InventoryUISystem = require(src:WaitForChild("InventoryUISystem"))
local SkillUISystem = require(src:WaitForChild("SkillUISystem"))
local CompanionUISystem = require(src:WaitForChild("CompanionUISystem"))
local StatUpgradeUISystem = require(src:WaitForChild("StatUpgradeUISystem"))
local QuestUISystem = require(src:WaitForChild("QuestUISystem"))
local GachaUISystem = require(src:WaitForChild("GachaUISystem"))
local RewardGaugeUISystem = require(src:WaitForChild("RewardGaugeUISystem"))
local GameManager = require(src:WaitForChild("GameManager"))

local modules = {
    HudSystem,
    InventoryUISystem,
    SkillUISystem,
    CompanionUISystem,
    StatUpgradeUISystem,
    QuestUISystem,
    GachaUISystem,
    RewardGaugeUISystem,
}

for _, mod in ipairs(modules) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
        if type(mod.start) == "function" then
            if mod == InventoryUISystem then
                mod:start(GameManager.itemSystem, nil, GameManager.systems.Stats, GameManager.setBonusSystem)
            elseif mod == SkillUISystem then
                mod:start(GameManager.skillSystem)
            elseif mod == CompanionUISystem then
                mod:start(GameManager.companionSystem)
            elseif mod == StatUpgradeUISystem then
                mod:start(GameManager.systems.Stats)
            elseif mod == QuestUISystem then
                mod:start(GameManager.systems.Quest)
            elseif mod == GachaUISystem then
                mod:start(GameManager)
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

