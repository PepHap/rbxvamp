local Players = game:GetService("Players")

-- Allow modules to be required using string paths like "src.Module" when
-- running inside Roblox. This matches the behavior expected by the Lua
-- test environment.
local originalRequire = require
local function pathRequire(target)
    if typeof(target) == "Instance" then
        return originalRequire(target)
    elseif type(target) == "string" then
        local current = game
        for part in string.gmatch(target, "[^%.]+") do
            current = current:WaitForChild(part)
        end
        return originalRequire(current)
    else
        return originalRequire(target)
    end
end
require = pathRequire

local GameManager = require(script.Parent.src.GameManager)

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
