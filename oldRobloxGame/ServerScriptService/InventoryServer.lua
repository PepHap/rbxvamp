local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(game.ReplicatedStorage.Modules.InventoryManager)

-- Создаём RemoteEvents
local equipEvent = Instance.new("RemoteEvent", ReplicatedStorage)
equipEvent.Name = "EquipItemEvent"

local inventoryUpdateEvent = Instance.new("RemoteEvent", ReplicatedStorage)
inventoryUpdateEvent.Name = "InventoryUpdateEvent"

local requestInventoryEvent = Instance.new("RemoteEvent", ReplicatedStorage)
requestInventoryEvent.Name = "RequestInventoryEvent"

-- Функция экипировки предмета
equipEvent.OnServerEvent:Connect(function(player, itemId, slot)
	local success, message = InventoryManager:EquipItem(player, itemId, slot)
	if success then
		local inventoryData = InventoryManager:GetInventoryData(player)
		print(inventoryData)
		inventoryUpdateEvent:FireClient(player, inventoryData.Items)
	end
end)

-- Отправка инвентаря при запросе
requestInventoryEvent.OnServerEvent:Connect(function(player)
	local inventoryData = InventoryManager:GetInventoryData(player)
	inventoryUpdateEvent:FireClient(player, inventoryData.Items)
end)
