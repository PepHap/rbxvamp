-- MobManager.lua
local MobManager = {}
local MobConfig = require(game.ReplicatedStorage.Configs.MobConfig)
local EventManager = require(game.ReplicatedStorage.Modules.EventManager)
local PlayerManager = require(game.ReplicatedStorage.Modules.PlayerManager)
local PlayerConfig = require(game.ReplicatedStorage.Configs.PlayerConfig)
local PathfindingService = game:GetService("PathfindingService")
local ServerStorage = game:GetService("ServerStorage")

local mobPrefabs = {
	Goblin = ServerStorage.Mobs.Goblin,
	Ogre = ServerStorage.Mobs.Ogre,
	Dragon = ServerStorage.Mobs.Dragon
}

-- Настраивает базовые параметры моба (здоровье, скорость)
local function configureMob(mob, config, level)
	local humanoid = mob:FindFirstChild("Humanoid")
	humanoid.MaxHealth = config.BaseHealth * (MobConfig.LevelMultiplier.Health ^ level)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = config.Speed
	return humanoid
end

-- Обрабатывает столкновения моба с игроком, нанося урон
local function setupTouchDamage(mob, calculatedDamage)
	mob.PrimaryPart.Touched:Connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player and player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid:TakeDamage(calculatedDamage)
				--humanoid:SetAttribute("creator", player.UserId)
				EventManager.Get("PlayerDamaged"):FireClient(player, calculatedDamage)
			end
		end
	end)
end

-- Обновляет путь моба к ближайшему игроку
local function followNearestPlayer(mob, humanoid)
	coroutine.wrap(function()
		local updateInterval = 0.1  -- интервал обновления пути
		while humanoid.Health > 0 do
			local targetPlayer = MobManager.FindNearestPlayer(mob.PrimaryPart.Position)
			if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
				local targetPos = targetPlayer.Character.PrimaryPart.Position
				humanoid:MoveTo(targetPos)
			end
			task.wait(updateInterval)
		end
	end)()
end

-- Обрабатывает смерть моба: отправка события и очистка
local function handleMobDeath(mob)
	local humanoid = mob:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function(hit)
			local killer = humanoid:GetAttribute("creator")
			killer = game.Players:GetPlayerByUserId(killer)
			
			if killer then				
				local xpReward = mob:GetAttribute("XP") or 10  -- Опыт за моба
				PlayerManager.AddXP(killer, xpReward, PlayerConfig)
				print(xpReward)
			end

			EventManager.Get("PlayerDamage"):FireAllClients("MobDied", mob)
			mob:Destroy()
		end)
	end
end

-- Функция для создания и настройки моба
function MobManager.SpawnMob(mobType, spawnPoint, level)
	local config = MobConfig.Types[mobType]
	if not config then
		warn("MobManager: Моб "..mobType.." не найден!")
		return
	end

	local prefab = mobPrefabs[mobType]
	if not prefab then
		warn("MobManager: Префаб для "..mobType.." не найден!")
		return
	end

	-- Клонируем модель и настраиваем расположение
	local mob = prefab:Clone()
	mob.PrimaryPart = mob:FindFirstChild("HumanoidRootPart")
	mob:SetPrimaryPartCFrame(spawnPoint.CFrame)
	mob.Parent = workspace:WaitForChild("Mobs")

	-- Настройка характеристик
	local humanoid = configureMob(mob, config, level)
	local calculatedDamage = config.Damage * (MobConfig.LevelMultiplier.Damage ^ level)

	-- Устанавливаем обработчики
	setupTouchDamage(mob, calculatedDamage)
	followNearestPlayer(mob, humanoid)
	handleMobDeath(mob)

	return mob
end

-- Находит ближайшего игрока по позиции
function MobManager.FindNearestPlayer(position)
	local closestPlayer, minDistance = nil, math.huge
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
			if distance < minDistance then
				closestPlayer = player
				minDistance = distance
			end
		end
	end
	return closestPlayer
end

return MobManager
