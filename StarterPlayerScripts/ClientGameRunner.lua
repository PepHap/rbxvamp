-- ClientGameRunner.lua
-- Starts GameManager client-side so UI modules become visible.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")
local GameManager = require(src.GameManager)

-- Enable Roblox objects for modules with UI when running in Studio
local modulesWithUI = {
    require(src.HudSystem),
    require(src.InventoryUISystem),
    require(src.SkillUISystem),
    require(src.CompanionUISystem),
    require(src.StatUpgradeUISystem),
    require(src.QuestUISystem),
    require(src.UISystem),
    require(src.PlayerSystem),
    require(src.PlayerInputSystem),
    require(src.EnemySystem),
    require(src.DataPersistenceSystem),
}
for _, mod in ipairs(modulesWithUI) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
    end
end

GameManager:start()
GameManager.systems.AutoBattle:enable()

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    GameManager:update(dt)
end)
