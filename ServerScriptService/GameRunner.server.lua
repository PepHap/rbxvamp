-- GameRunner.lua
-- Entry point script for starting the game within Roblox Studio.

-- Override require so that modules can be loaded via string paths like
-- "src.Module" when running inside Roblox. This mirrors the plain Lua test
-- environment where such paths are valid.
local originalRequire = require
local function pathRequire(target)
    if typeof(target) == "Instance" then
        return originalRequire(target)
    elseif type(target) == "string" then
        -- Support requiring modules using paths like "src.Module" or "assets.Data"
        local parts = {}
        for part in string.gmatch(target, "[^%.]+") do
            table.insert(parts, part)
        end

        local root = game
        if parts[1] == "src" then
            -- Modules may live under ServerScriptService or ReplicatedStorage
            local sss = game:GetService("ServerScriptService")
            local rs = game:GetService("ReplicatedStorage")
            root = sss:FindFirstChild("src") or rs:FindFirstChild("src") or root
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

local GameManager = require(script.Parent.src.GameManager)

-- Enable Roblox object creation for modules that support it so the
-- user can actually see models and interfaces when running the game
local modulesWithUI = {
    require(script.Parent.src.HudSystem),
    require(script.Parent.src.InventoryUISystem),
    require(script.Parent.src.SkillUISystem),
    require(script.Parent.src.CompanionUISystem),
    require(script.Parent.src.StatUpgradeUISystem),
    require(script.Parent.src.QuestUISystem),
    require(script.Parent.src.UISystem),
    require(script.Parent.src.PlayerSystem),
    require(script.Parent.src.PlayerInputSystem),
    require(script.Parent.src.EnemySystem),
    require(script.Parent.src.DataPersistenceSystem),
}
for _, mod in ipairs(modulesWithUI) do
    if type(mod) == "table" then
        mod.useRobloxObjects = true
    end
end

GameManager:start()
GameManager.systems.AutoBattle:enable()

local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute then
        player:SetAttribute("SaveData", data)
    end
    -- Start automatic saving for this player's data
    GameManager.autoSaveSystem:start(
        GameManager.saveSystem,
        player.UserId,
        function()
            if player.GetAttribute then
                return player:GetAttribute("SaveData")
            end
        end
    )
end)

Players.PlayerRemoving:Connect(function(player)
    local data
    if player.GetAttribute then
        data = player:GetAttribute("SaveData")
    end
    if data then
        GameManager:savePlayerData(player.UserId, data)
    end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

