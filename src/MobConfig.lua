-- MobConfig.lua
-- Defines base stats for each enemy type and scaling per level

local MobConfig = {
    Types = {
        Goblin = {
            BaseHealth = 60,
            Damage = 5,
            Speed = 8,
            AttackCooldown = 1.5,
            Prefab = "Goblin"
        },
        Ogre = {
            BaseHealth = 300,
            Damage = 20,
            Speed = 6,
            AttackCooldown = 2.5,
            Prefab = "Ogre"
        },
        Dragon = {
            BaseHealth = 1500,
            Damage = 40,
            Speed = 10,
            AttackCooldown = 3,
            Prefab = "Dragon"
        },
        Skeleton = {
            BaseHealth = 80,
            Damage = 7,
            Speed = 9,
            AttackCooldown = 1.5,
            Prefab = "Skeleton"
        }
    },
    LevelMultiplier = {
        Health = 1.1,
        Damage = 1.08
    }
}

return MobConfig
