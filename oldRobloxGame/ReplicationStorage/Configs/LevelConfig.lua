local LevelConfig = {
	BaseXP = 100,  -- Базовое количество XP для 1 уровня
	XPMultiplier = 1.5,  -- Множитель для следующего уровня
	MaxLevel = 100,  -- Максимальный уровень
	StatPerLevel = {  -- Бонусы за уровень
		ATK = 5,
		HP = 20,
		DEF = 2,
		CRIT_CHANCE = 0.01,
		-- Добавьте другие характеристики
	}
}
return LevelConfig