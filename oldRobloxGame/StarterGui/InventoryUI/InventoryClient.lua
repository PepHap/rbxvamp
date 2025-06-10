local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui") -- Исправлено: UI берется из PlayerGui
local InventoryUI = PlayerGui:WaitForChild("InventoryUI") -- GUI теперь в PlayerGui
local inventoryFrame = InventoryUI:WaitForChild("InventoryFrame")
local equipmentSlots = inventoryFrame:WaitForChild("EquipmentSlots")
local inventorySlots = inventoryFrame:WaitForChild("InventorySlots")
local pageButtons = inventoryFrame:WaitForChild("PageButtons")
local statsPanel = inventoryFrame:WaitForChild("StatsPanel")
local blurEffect = Instance.new("BlurEffect", game.Lighting)
blurEffect.Size = 0

-- Получаем модули и события
local InventoryManager = require(ReplicatedStorage.Modules.InventoryManager)
local EquipSlots = InventoryManager:GetEquipSlots()
local EventManager = ReplicatedStorage.Events

local currentPage = 1
local maxPages = 3
local itemsPerPage = 24
local isInventoryOpen = true

-- Настройки анимации
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

-- Функция анимированного открытия/закрытия
local function toggleInventory(visible)
	local goal = {
		Position = visible and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1.5, 0),
		Size = visible and UDim2.new(0, 1200, 0, 800) or UDim2.new(0, 1200, 0, 0)
	}
	local tween = TweenService:Create(inventoryFrame, tweenInfo, goal)
	tween:Play()

	blurEffect.Size = visible and 10 or 0
end

-- Функция обновления интерфейса
local function updateInventoryUI(inventoryData, playerStats)
	warn("Обновляем UI. Количество предметов:", #inventoryData.Items)
	equipmentSlots:ClearAllChildren()
	inventorySlots:ClearAllChildren()

	-- Пересчитываем количество страниц
	maxPages = math.max(1, math.ceil(#inventoryData.Items / itemsPerPage)) -- TODO

	-- Убеждаемся, что страница в пределах допустимого диапазона
	currentPage = math.clamp(currentPage, 1, maxPages)
	statsPanel:ClearAllChildren()

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "Статистика"
	title.TextScaled = true
	title.BackgroundTransparency = 1
	title.Parent = statsPanel

	local layout = Instance.new("UIListLayout")
	layout.Parent = statsPanel
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5) -- Отступы между строками

	for statName, statValue in pairs(playerStats) do
		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 0, 25) -- Увеличенный размер строки
		statLabel.Text = statName .. ": " .. tostring(statValue)
		statLabel.TextScaled = true
		statLabel.BackgroundTransparency = 1
		statLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Белый текст для контраста
		statLabel.Parent = statsPanel
	end


	-- Создаем UIGridLayout для сетки экипировки
	local equipLayout = Instance.new("UIGridLayout")
	equipLayout.CellSize = UDim2.new(0, 80, 0, 80)
	equipLayout.FillDirection = Enum.FillDirection.Horizontal
	equipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	equipLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	equipLayout.Parent = equipmentSlots

	-- Создаем UIGridLayout для сетки инвентаря
	local invLayout = Instance.new("UIGridLayout")
	invLayout.CellSize = UDim2.new(0, 60, 0, 60)
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	invLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	invLayout.Parent = inventorySlots

	-- Создаем слоты экипировки
	for _, slotName in ipairs(EquipSlots) do
		warn("Создаем слот экипировки:", slotName)
		local slotFrame = Instance.new("Frame")
		slotFrame.Size = UDim2.new(0, 80, 0, 80)
		slotFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		slotFrame.BorderSizePixel = 1
		slotFrame.Parent = equipmentSlots

		local itemLabel = Instance.new("TextLabel")
		itemLabel.Size = UDim2.new(1, 0, 0.3, 0)
		itemLabel.Text = slotName
		itemLabel.TextScaled = true
		itemLabel.BackgroundTransparency = 1
		itemLabel.Parent = slotFrame

		local itemButton = Instance.new("TextButton")
		itemButton.Size = UDim2.new(1, 0, 0.7, 0)
		itemButton.Position = UDim2.new(0, 0, 0.3, 0)
		itemButton.Text = inventoryData.Equipped[slotName] and inventoryData.Equipped[slotName].Name or "Пусто"
		itemButton.TextScaled = true
		itemButton.Parent = slotFrame

		itemButton.MouseButton1Click:Connect(function()
			ReplicatedStorage.Events.UnequipItemEvent:FireServer(slotName)
		end)
	end

	-- Создаем слоты инвентаря
	local startIdx = (currentPage - 1) * itemsPerPage + 1
	local endIdx = math.min(startIdx + itemsPerPage - 1, #inventoryData.Items)

	for i = startIdx, endIdx do
		local item = inventoryData.Items[i]
		local itemButton = Instance.new("TextButton")
		itemButton.Size = UDim2.new(0, 60, 0, 60)
		itemButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		itemButton.Text = item and item.Name or "Пусто"
		itemButton.TextScaled = true
		itemButton.Parent = inventorySlots

		if item and InventoryManager:IsItemEquipped(player, item.Id) then
			itemButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			itemButton.Text = "[Экип.] " .. item.Name
		end

		itemButton.MouseButton1Click:Connect(function()
			if item then
				ReplicatedStorage.Events.EquipItemEvent:FireServer(item.Id, item.Slot)
			end
		end)
	end
end

-- Функция переключения страниц
local function changePage(direction)
	currentPage = math.clamp(currentPage + direction, 1, maxPages)
	warn("Переключение страницы:", currentPage)
	ReplicatedStorage.RequestInventoryEvent:FireServer()
end

local prevButton = Instance.new("TextButton")
prevButton.Size = UDim2.new(0, 60, 0, 40)
prevButton.Position = UDim2.new(0, 10, 1, -50) -- Лево
prevButton.Text = "<"
prevButton.Parent = pageButtons
prevButton.MouseButton1Click:Connect(function()
	changePage(-1)
end)

local nextButton = Instance.new("TextButton")
nextButton.Size = UDim2.new(0, 60, 0, 40)
nextButton.Position = UDim2.new(1, -70, 1, -50) -- Право
nextButton.Text = ">"
nextButton.Parent = pageButtons
nextButton.MouseButton1Click:Connect(function()
	changePage(1)
end)

-- Открытие инвентаря на клавишу "E"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E and not gameProcessed then
		isInventoryOpen = not isInventoryOpen
		toggleInventory(isInventoryOpen)

		if isInventoryOpen then
			ReplicatedStorage.RequestInventoryEvent:FireServer(currentPage) 
		end
	end
end)

-- Обработчик обновления инвентаря
EventManager.UpdateInventory.OnClientEvent:Connect(function(inventoryData, playerStats)
	updateInventoryUI(inventoryData, playerStats)
end)


-- Первоначальная загрузка инвентаря
ReplicatedStorage.RequestInventoryEvent:FireServer(currentPage) 


local EventMngr = require(game.ReplicatedStorage.Modules.EventManager)

-- Обновление XP
EventMngr.Get("UpdatePlayerXP").OnClientEvent:Connect(function(xp, requiredXP, level)
	-- Пример: Обновите текстовые поля
	--script.Parent.XPText.Text = `XP: {xp}/{requiredXP}`
	--script.Parent.LevelText.Text = `Level: {level}`
	print(xp, requiredXP, level)
end)

-- Уведомление о повышении уровня
EventMngr.Get("PlayerLevelUp").OnClientEvent:Connect(function(level)
	print(`Вы достигли уровня {level}!`)
	-- Пример: Показать анимацию или сообщение
end)