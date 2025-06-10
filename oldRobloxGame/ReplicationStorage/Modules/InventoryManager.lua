-- InventoryManager.lua
local InventoryManager = {}

-- Таблица для хранения инвентарей игроков (ключ – UserId игрока)
local playerInventories = {}

-- Слоты экипировки (можно расширять по необходимости)
local EquipSlots = {
	"Hat",         -- Шляпа/Головной убор
	"Necklace",    -- Ожерелье
	"Ring",        -- Кольцо
	"UpperClothing", -- Верхняя одежда
	"Accessory",   -- Аксессуар
	"Weapon"       -- Оружие
}

------------------------------------------------
-- Инициализация инвентаря для игрока
------------------------------------------------
function InventoryManager:InitializeInventory(player)
	-- Создаём структуру инвентаря:
	-- Items - список всех предметов, которые находятся в инвентаре (не экипированы)
	-- Equipped - таблица для экипированных предметов по слотам
	if not playerInventories[player.UserId] then
		playerInventories[player.UserId] = {
			Items = {},
			Equipped = {}  -- Заполняем слоты nil-значениями
		}
		for _, slot in ipairs(EquipSlots) do
			playerInventories[player.UserId].Equipped[slot] = nil
		end
	end
end

------------------------------------------------
-- Получение инвентаря игрока
------------------------------------------------
function InventoryManager:GetInventory(player)
	--print("FROM GetInventory() ---", "Player:", player, "player id:",player.UserId, "player inventory:", playerInventories)
	return playerInventories[player.UserId]
end

------------------------------------------------
-- Добавление предмета в инвентарь
-- item должен быть таблицей с полями:
--   Id (уникальный идентификатор предмета),
--   Name, 
--   Slot (название слота, в который может быть одет, например, "Hat")
--   и другими характеристиками, например, статистикой.
------------------------------------------------
function InventoryManager:AddItem(player, item)
	local inventory = self:GetInventory(player)
	if inventory then
		table.insert(inventory.Items, item)
	else
		warn("InventoryManager:AddItem - инвентарь для игрока не инициализирован!")
	end
end

------------------------------------------------
-- Удаление предмета из инвентаря по его Id
------------------------------------------------
function InventoryManager:RemoveItem(player, itemId)
	local inventory = self:GetInventory(player)
	if inventory then
		for i, item in ipairs(inventory.Items) do
			if item.Id == itemId then
				table.remove(inventory.Items, i)
				return true
			end
		end
	end
	return false
end

------------------------------------------------
-- Экипировка предмета.
-- itemId - уникальный идентификатор предмета в инвентаре.
-- slot - слот, в который необходимо экипировать (например, "Hat").
-- Если в слоте уже есть предмет, его можно вернуть в инвентарь (или можно заблокировать экипировку).
------------------------------------------------
function InventoryManager:EquipItem(player, itemId, slot)
	local inventory = self:GetInventory(player)
	if not inventory then
		return false, "Инвентарь не инициализирован"
	end

	-- Найдем предмет в списке Items
	local item, index
	for i, it in ipairs(inventory.Items) do
		if it.Id == itemId then
			item = it
			index = i
			break
		end
	end
	if not item then
		return false, "Предмет не найден"
	end

	-- Проверим, можно ли экипировать этот предмет в указанный слот
	if item.Slot ~= slot then
		return false, "Невозможно экипировать предмет в слот " .. slot
	end

	-- Если в слоте уже есть предмет, можно вернуть его в инвентарь
	if inventory.Equipped[slot] then
		table.insert(inventory.Items, inventory.Equipped[slot])
	end

	-- Экипируем предмет: удаляем из Items и помещаем в Equipped
	inventory.Equipped[slot] = item	
	table.remove(inventory.Items, index)
	return true, "Предмет экипирован"
end

------------------------------------------------
-- Снятие экипировки из указанного слота.
-- Предмет возвращается в общий инвентарь.
------------------------------------------------
function InventoryManager:UnequipItem(player, slot)
	local inventory = self:GetInventory(player)
	if not inventory then
		return false, "Инвентарь не инициализирован"
	end

	local item = inventory.Equipped[slot]
	--print("item unequip",item)
	if not item then
		return false, "В слоте " .. slot .. " нет экипированного предмета"
	end

	-- Возвращаем предмет в список Items
	table.insert(inventory.Items, item)
	inventory.Equipped[slot] = nil
	
	return true, "Предмет снят"
end

------------------------------------------------
-- Функция для получения данных инвентаря (список предметов и экипированных элементов)
------------------------------------------------
function InventoryManager:GetInventoryData(player)
	local inventory = self:GetInventory(player)
	if inventory then
		return {
			Items = inventory.Items,
			Equipped = inventory.Equipped
		}
	end
	warn("Инвентарь не найден для игрока:", player.Name)
	return nil
end


function InventoryManager:IsItemEquipped(player, itemId)
	local inventory = self:GetInventory(player)
	if not inventory then return false end

	-- Проверяем все слоты экипировки
	for slotName, item in pairs(inventory.Equipped) do
		if item and item.Id == itemId then
			return true
		end
	end
	return false
end


function InventoryManager:GetItemData(player, itemId)
	local inventory = self:GetInventory(player)
	if not inventory then return nil end
	-- Проверяем все слоты экипировки
	for slotName, item in pairs(inventory.Equipped) do
		if item and item.Id == itemId then
			return item
		end
	end
	return nil
end


function InventoryManager:GetEquipSlots()
	return EquipSlots
end

return InventoryManager
