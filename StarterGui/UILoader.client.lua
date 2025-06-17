-- UILoader.client.lua
-- Initializes UI modules client-side using a LocalScript so
-- each player gets their own interface rendered locally.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")
local ItemSystem = require(src:WaitForChild("ItemSystem"))

local HudSystem = require(src:WaitForChild("HudSystem"))
local InventoryUISystem = require(src:WaitForChild("InventoryUISystem"))
local SkillUISystem = require(src:WaitForChild("SkillUISystem"))
local CompanionUISystem = require(src:WaitForChild("CompanionUISystem"))
local StatUpgradeUISystem = require(src:WaitForChild("StatUpgradeUISystem"))
local QuestUISystem = require(src:WaitForChild("QuestUISystem"))
local GachaUISystem = require(src:WaitForChild("GachaUISystem"))
local RewardGaugeUISystem = require(src:WaitForChild("RewardGaugeUISystem"))

local modules = {
    HudSystem,
    {mod = InventoryUISystem, args = {ItemSystem}},
    SkillUISystem,
    CompanionUISystem,
    StatUpgradeUISystem,
    QuestUISystem,
    GachaUISystem,
    RewardGaugeUISystem,
}

for _, entry in ipairs(modules) do
    local mod, args =
        (typeof(entry) == "table" and entry.mod) and entry.mod or entry,
        (typeof(entry) == "table" and entry.args) or {}
    if type(mod) == "table" then
        mod.useRobloxObjects = true
        if type(mod.start) == "function" then
            mod:start(table.unpack(args))
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

