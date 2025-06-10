-- CombatManager.lua
local CombatManager = {}
local PlayerConfig = require(game.ReplicatedStorage.Configs.PlayerConfig)

-- Функция для получения всех мобов в заданном радиусе от позиции
local function getMobsInRadius(position, radius)
	local mobsInRange = {}
	local mobsFolder = workspace:WaitForChild("Mobs")
	for _, mob in ipairs(mobsFolder:GetChildren()) do
		if mob.PrimaryPart then
			local distance = (mob.PrimaryPart.Position - position).Magnitude
			if distance <= radius then
				table.insert(mobsInRange, mob)
			end
		end
	end
	return mobsInRange
end

-- Функция для атаки мобов
-- Параметры (опциональные):
-- player - игрок, совершающий атаку
-- radius - радиус атаки (если nil, берём из PlayerConfig.AttackRadius)
-- numberOfTargets - количество целей (если nil, берём из PlayerConfig.NumberOfTargets)
-- damage - урон, наносимый каждой цели (если nil, берём из PlayerConfig.AttackDamage)
function CombatManager.Attack(player, radius, numberOfTargets, damage)
	radius = radius or PlayerConfig.AttackRadius
	numberOfTargets = numberOfTargets or PlayerConfig.NumberOfTargets
	damage = damage or PlayerConfig.ATK

	local character = player.Character
	if not character or not character.PrimaryPart then return end
	local playerPosition = character.PrimaryPart.Position

	-- Получаем всех мобов в заданном радиусе
	local mobs = getMobsInRadius(playerPosition, radius)
	if #mobs == 0 then
		return  -- В радиусе нет врагов
	end

	-- Сортируем мобов по расстоянию от игрока (от меньшего к большему)
	table.sort(mobs, function(a, b)
		return (a.PrimaryPart.Position - playerPosition).Magnitude < (b.PrimaryPart.Position - playerPosition).Magnitude
	end)

	-- Выбираем нужное количество целей (либо меньше, если мобов меньше)
	local targets = {}
	for i = 1, math.min(numberOfTargets, #mobs) do
		table.insert(targets, mobs[i])
	end

	-- Наносим урон каждой выбранной цели
	for _, mob in ipairs(targets) do
		local humanoid = mob:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(damage)
			humanoid:SetAttribute("creator", player.UserId)
			--print(humanoid:GetAttribute("creator"))
			-- Можно добавить отправку события, например, уведомление игрока о попадании
			-- local EventManager = require(game.ReplicatedStorage.Modules.EventManager)
			-- EventManager.Get("PlayerDamaged"):FireClient(player, damage)
		end
	end
end

return CombatManager
