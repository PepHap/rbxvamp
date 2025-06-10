-- PlayerManager.lua
local PlayerManager = {}
local PlayerConfig = require(game.ReplicatedStorage.Configs.PlayerConfig)
local LevelConfig = require(game.ReplicatedStorage.Configs.LevelConfig)
local EventManager = require(game.ReplicatedStorage.Modules.EventManager)
local InventoryManager = require(game.ReplicatedStorage.Modules.InventoryManager)

local playerData = {}

-- Функция для установки базовых параметров персонажа
local function initializeCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = PlayerConfig.HP
	humanoid.Health = humanoid.MaxHealth
end

-- Функция обработки урона для данного игрока
local function setupDamageHandler(player)
	-- Используем локальную функцию-обработчик, чтобы не создавать дублирующиеся соединения
	local function onMobAttack(receiverPlayer, damage)
		if receiverPlayer ~= player then return end
		local character = player.Character
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			-- Гарантируем, что урон не отрицательный
			local effectiveDamage = math.max(damage - PlayerConfig.DEF, 0)
			humanoid:TakeDamage(effectiveDamage)
			EventManager.Get("PlayerDamage"):FireClient(player, "PlayerDamaged", effectiveDamage)
		end
	end

	EventManager.Get("MobAttack").OnServerEvent:Connect(onMobAttack)
end

function PlayerManager.Init(player)
	-- Инициализация данных игрока
	playerData[player] = {
		Level = 1,
		XP = 0,
		RequiredXP = LevelConfig.BaseXP
	}

	-- Привязка событий
	player.CharacterAdded:Connect(function(character)
		PlayerManager.applyPlayerStats(player, PlayerConfig)
	end)

	-- Обработка смерти игрока
	player.CharacterRemoving:Connect(function()
		playerData[player] = nil
	end)
end


function PlayerManager.AddXP(player, amount, stats)
	local data = playerData[player]
	if not data then return end

	data.XP = data.XP + amount

	-- Проверка на повышение уровня
	while data.XP >= data.RequiredXP and data.Level < LevelConfig.MaxLevel do
		data.XP = data.XP - data.RequiredXP
		data.Level = data.Level + 1
		data.RequiredXP = math.floor(data.RequiredXP * LevelConfig.XPMultiplier)

		-- Применяем бонусы за уровень
		PlayerManager.ApplyLevelUp(player, PlayerConfig)
	end

	-- Обновляем UI
	EventManager.Get("UpdatePlayerXP"):FireClient(player, data.XP, data.RequiredXP, data.Level)
end


function PlayerManager.ApplyLevelUp(player, stats)
	local data = playerData[player]
	if not data then return end

	-- Увеличиваем характеристики
	for stat, value in pairs(LevelConfig.StatPerLevel) do
		PlayerConfig[stat] = (PlayerConfig[stat] or 0) + value
	end

	-- Применяем обновленные характеристики
	PlayerManager.applyPlayerStats(player, PlayerConfig)

	-- Уведомляем игрока
	EventManager.Get("PlayerLevelUp"):FireClient(player, data.Level)
end


function PlayerManager.applyPlayerStats(player, stats)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = stats.HP
	end

	PlayerConfig.ATK = stats.ATK + 100

	-- player:SetAttribute("ATK", stats.ATK)
	player:SetAttribute("ATK_SPEED", stats.ATK_SPEED) -- TODO CHANGE TO PlayerConfig
	player:SetAttribute("DODGE", stats.DODGE) -- TODO CHANGE TO PlayerConfig
	-- и так далее...
end


game.Players.PlayerAdded:Connect(function(player)
	-- Инициализируем инвентарь для нового игрока
	InventoryManager:InitializeInventory(player)

	-- Другой код инициализации персонажа...
	player.CharacterAdded:Connect(function(character)
		-- Например, установка базовых характеристик персонажа
	end)
end)

return PlayerManager
