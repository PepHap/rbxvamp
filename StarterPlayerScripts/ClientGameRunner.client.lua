-- ClientGameRunner.lua
-- Starts GameManager client-side so UI modules become visible.

-- Provide a require function that accepts string paths like "src.Module" when
-- executed within Roblox Studio. This mirrors how the plain Lua environment
-- loads modules during automated tests.
local originalRequire = require
local function pathRequire(target)
    if typeof(target) == "Instance" then
        return originalRequire(target)
    elseif type(target) == "string" then
        local parts = {}
        for part in string.gmatch(target, "[^%.]+") do
            table.insert(parts, part)
        end

        local root = game
        if parts[1] == "src" then
            local rs = game:GetService("ReplicatedStorage")
            local sss = game:GetService("ServerScriptService")
            root = rs:FindFirstChild("src") or sss:FindFirstChild("src") or root
            table.remove(parts, 1)
        elseif parts[1] == "assets" then
            root = game:GetService("ReplicatedStorage"):FindFirstChild("assets") or root
            table.remove(parts, 1)
        end

        for _, part in ipairs(parts) do
            root = root:WaitForChild(part)
        end
        return originalRequire(root)
    else
        return originalRequire(target)
    end
end
require = pathRequire

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
