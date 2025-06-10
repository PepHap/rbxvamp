local MobConfig = {
	Types = {
		Goblin = {
			BaseHealth = 60,
			Damage = 0,
			Speed = 5,
			AttackCooldown = 1.5,
			XP = 50,
			Coins = 5,
			ScaleFactor = 1.0,
			Prefab = "Goblin" -- Соответствует имени модели в ServerStorage.Mobs
		},
		Ogre = {
			BaseHealth = 300,
			Damage = 0,
			Speed = 8,
			AttackCooldown = 3,
			XP = 50,
			Coins = 25,
			ScaleFactor = 1.8
		},
		Dragon = {
			BaseHealth = 1500,
			Damage = 100,
			Speed = 20,
			AttackCooldown = 5,
			XP = 50,
			Coins = 150,
			ScaleFactor = 3.5
		}
	},
	LevelMultiplier = {
		Health = 1.15, -- Усиление здоровья за уровень
		Damage = 1.08 -- Усиление урона за уровень
	}
}
return MobConfig