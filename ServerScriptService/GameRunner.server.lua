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

local src = script.Parent:WaitForChild("src")
local GameManager = require(src:WaitForChild("GameManager"))

-- Enable Roblox object creation for modules that support it so the
-- user can actually see models and interfaces when running the game
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

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

Players.PlayerAdded:Connect(function(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute and HttpService then
        local encoded = HttpService:JSONEncode(data)
        player:SetAttribute("SaveData", encoded)
    end
    -- Start automatic saving for this player's data
    GameManager.autoSaveSystem:start(
        GameManager.saveSystem,
        player.UserId,
        function()
            if player.GetAttribute and HttpService then
                local json = player:GetAttribute("SaveData")
                if json then
                    local success, decoded = pcall(function()
                        return HttpService:JSONDecode(json)
                    end)
                    if success then
                        return decoded
                    end
                end
            end
        end
    )
end)

Players.PlayerRemoving:Connect(function(player)
    local json
    if player.GetAttribute then
        json = player:GetAttribute("SaveData")
    end
    if json and HttpService then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if success then
            GameManager:savePlayerData(player.UserId, decoded)
        end
    end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)

