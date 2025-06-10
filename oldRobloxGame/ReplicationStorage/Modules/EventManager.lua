-- EventManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {
	MobSpawned = "MobSpawned",
	PlayerDamaged = "PlayerDamaged",
	MobDied = "MobDied",
	MobAttack = "MobAttack",
	PlayerDamage = "PlayerDamage",
	PlayerAttack = "PlayerAttack",
	UpdateInventory = "UpdateInventory",
	UpdatePlayerXP = "UpdatePlayerXP",
	PlayerLevelUp = "PlayerLevelUp"
}

local remoteEventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
remoteEventsFolder.Name = "Events"
remoteEventsFolder.Parent = ReplicatedStorage

local EventManager = {}

function EventManager.Init()
	for eventName, _ in pairs(Events) do
		if not remoteEventsFolder:FindFirstChild(eventName) then
			Instance.new("RemoteEvent", remoteEventsFolder).Name = eventName
		end
	end
end

function EventManager.Get(eventName)
	-- Проверка на существование события
	if not Events[eventName] then
		error("Событие " .. eventName .. " не зарегистрировано!")
	end

	-- Ожидание и возврат события
	return remoteEventsFolder:FindFirstChild(eventName)
end

return EventManager
