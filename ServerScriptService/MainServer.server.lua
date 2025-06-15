local Players = game:GetService("Players")

-- Allow modules to be required using string paths like "src.Module" when
-- running inside Roblox. This matches the behavior expected by the Lua
-- test environment.
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

local function onPlayerAdded(player)
    local data = GameManager:loadPlayerData(player.UserId)
    if player.SetAttribute then
        player:SetAttribute("SaveData", data)
    end
end

local function onPlayerRemoving(player)
    local data
    if player.GetAttribute then
        data = player:GetAttribute("SaveData")
    end
    if data then
        GameManager:savePlayerData(player.UserId, data)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
