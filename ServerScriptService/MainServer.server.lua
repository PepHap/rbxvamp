local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

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
    if player.SetAttribute and HttpService then
        local encoded = HttpService:JSONEncode(data)
        player:SetAttribute("SaveData", encoded)
    end
end

local function onPlayerRemoving(player)
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
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
