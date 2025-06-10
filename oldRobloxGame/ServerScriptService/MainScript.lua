-- ServerMain.lua
local EventManager = require(game.ReplicatedStorage.Modules.EventManager)

local MobManager = require(game.ReplicatedStorage.Modules.MobManager)
local PlayerManager = require(game.ReplicatedStorage.Modules.PlayerManager)
local CombatManager = require(game.ReplicatedStorage.Modules.CombatManager)
local InventoryManager = require(game.ReplicatedStorage.Modules.InventoryManager)

local PlayerConfig = require(game.ReplicatedStorage.Configs.PlayerConfig)

local EquipItemEvent = game.ReplicatedStorage.Events:WaitForChild("EquipItemEvent")
local UnequipItemEvent = game.ReplicatedStorage.Events:WaitForChild("UnequipItemEvent")


-- Функция инициализации
local function initializeGame()
	EventManager.Init()
	local mobsFolder = workspace:WaitForChild("Mobs")
	mobsFolder:ClearAllChildren()
end

-- Функция настройки зон спавна
local function getSpawnZones()
	return {
		{ MobType = "Goblin", Level = 1, SpawnPoint = workspace.SpawnPoints.GoblinSpawn },
		{ MobType = "Ogre", Level = 5, SpawnPoint = workspace.SpawnPoints.OgreSpawn }
	}
end

-- Функция цикла спавна мобов
local function spawnLoop()
	local spawnZones = getSpawnZones()
	while true do
		
		for _, zone in ipairs(spawnZones) do
			MobManager.SpawnMob(zone.MobType, zone.SpawnPoint, zone.Level)
		end
		task.wait(3) ---
	end
end


local function calculatePlayerStats(player)
	-- Копируем базовые характеристики из PlayerConfig
	local stats = table.clone(PlayerConfig)

	-- Получаем инвентарь игрока
	local inventory = InventoryManager:GetInventory(player)
	local equippedItems = inventory.Equipped

	-- Применяем характеристики от экипированных предметов
	for slot, itemId in pairs(equippedItems) do
		local item = InventoryManager:GetItemData(player, itemId.Id)
		if item and item.Stats then
			for stat, value in pairs(item.Stats) do
				if stats[stat] then
					stats[stat] = stats[stat] + value
				end
			end
		end
	end

	return stats
end



-- Функция инициализации игроков
local function initializePlayers()
	-- Подключаем обработчик для каждого нового игрока
	game.Players.PlayerAdded:Connect(function(player)
		InventoryManager:InitializeInventory(player)
		PlayerManager.Init(player) -- Инициализация игрока через PlayerManager

		local newItem = {
			Id = "item_001",
			Name = "Шляпа Мастера",
			Slot = "Weapon",
			Stats = {
				ATK = 10,  -- Бонус к урону
				ATK_SPEED = 0.1,  -- Бонус к скорости атаки (10%)
				DODGE = 5,  -- Бонус к уклонению
				HP = 50,  -- Бонус к здоровью
				-- и так далее для других характеристик
			}
		}
		
		InventoryManager:AddItem(player, newItem)	
		InventoryManager:EquipItem(player, newItem.Id, "Weapon")	
		
		local inventoryData = InventoryManager:GetInventoryData(player)
		
		local playerStats = calculatePlayerStats(player)
		
		task.wait(3) -- TODO FIX SHIT
		
		PlayerManager:applyPlayerStats(player, playerStats)
		
		--print("Экипированные предметы:", InventoryManager:GetInventory(player).Equipped)
		
		EventManager.Get("UpdateInventory"):FireClient(player, inventoryData, playerStats)
		
		
	end)
end


EventManager.Get("PlayerAttack").OnServerEvent:Connect(function(player, radius, numberOfTargets, damage)
	CombatManager.Attack(player, radius, numberOfTargets, damage)
end)


UnequipItemEvent.OnServerEvent:Connect(function(player, slot)
	--print("unequip func", InventoryManager:GetInventory(player), " for player", player, " player id ", player.UserId)
	local success, message = InventoryManager:UnequipItem(player, slot)
	if success then

		local playerStats = calculatePlayerStats(player)
		local inventoryData = InventoryManager:GetInventoryData(player)
		
		PlayerManager:applyPlayerStats(player, playerStats)

		EventManager.Get("UpdateInventory"):FireClient(player, inventoryData, playerStats)
	else
		warn(message)
	end
end)

EquipItemEvent.OnServerEvent:Connect(function(player, itemId, slot)
	local success, message = InventoryManager:EquipItem(player, itemId, slot)
	if success then
		
		local playerStats = calculatePlayerStats(player)
		local inventoryData = InventoryManager:GetInventoryData(player)
		
		PlayerManager:applyPlayerStats(player, playerStats)
		
		EventManager.Get("UpdateInventory"):FireClient(player, inventoryData, playerStats)		
	else
		warn(message)
	end
end)


-- Основной запуск
initializeGame()
initializePlayers()
spawnLoop()  -- Этот вызов запускает бесконечный цикл спавна
