-- PlayerConfig.lua
local PlayerConfig = {
	ATK = 10,  -- Начальное значение атаки
	ATK_SPEED = 1.0,  -- Начальная скорость атаки
	DODGE = 0,  -- Начальное уклонение
	HP = 100,  -- Начальное здоровье
	DEF = 10,  -- Начальная защита
	CRIT_CHANCE = 0.05,  -- Начальный шанс критического удара
	CRIT_DAMAGE = 1.5,  -- Начальный множитель критического урона
	
	
	MoveSpeed = 16,
	BaseDamage = 10,

	-- Параметры атаки
	AttackRadius = 10,       -- базовый радиус атаки
	NumberOfTargets = 3,     -- базовое количество целей (можно улучшать)

}

return PlayerConfig
