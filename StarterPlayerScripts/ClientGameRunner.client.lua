-- ClientGameRunner.lua
-- Starts GameManager client-side so UI modules become visible.


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local src = ReplicatedStorage:WaitForChild("src")
local GameManager = require(src:WaitForChild("GameManager"))

-- Enable Roblox objects for modules with UI when running in Studio
local modulesWithUI = {
    require(src:WaitForChild("HudSystem")),
    require(src:WaitForChild("InventoryUISystem")),
    require(src:WaitForChild("SkillUISystem")),
    require(src:WaitForChild("CompanionUISystem")),
    require(src:WaitForChild("StatUpgradeUISystem")),
    require(src:WaitForChild("QuestUISystem")),
    require(src:WaitForChild("UISystem")),
    require(src:WaitForChild("PlayerSystem")),
    require(src:WaitForChild("PlayerInputSystem")),
    require(src:WaitForChild("EnemySystem")),
    require(src:WaitForChild("DataPersistenceSystem")),
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
