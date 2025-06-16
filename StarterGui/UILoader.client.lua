-- UILoader.client.lua
-- Initializes UI modules client-side using a LocalScript so
-- each player gets their own interface rendered locally.

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
            mod:start()
        end
    end
end

