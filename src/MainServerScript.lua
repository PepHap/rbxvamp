local Players = game:GetService("Players")
local GameManager = require(script.Parent.Modules.GameManager)

local managers = {}

local function onPlayerAdded(player)
    managers[player.UserId] = GameManager.new(player)
    managers[player.UserId].Monsters = managers[player.UserId].MonsterManager:SpawnMonsters()
end

local function onPlayerRemoving(player)
    managers[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
