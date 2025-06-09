-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}

---Utility to create a basic enemy table. The returned table describes the
--  enemy's health, damage, current position and optional type string.
--  @param health number
--  @param damage number
--  @param position table table containing x/y/z coordinates
--  @param enemyType string|nil classification such as "mini" or "boss"
--  @return table new enemy object
local function createEnemy(health, damage, position, enemyType)
    return {
        health = health,
        damage = damage,
        position = position,
        type = enemyType
    }
end

---List of currently active enemies in the world.
EnemySystem.enemies = {}

---Last level used when spawning a wave.
EnemySystem.lastWaveLevel = nil

---Last boss type that was spawned.
EnemySystem.lastBossType = nil

---Creates a wave of enemies scaled by the provided level.
-- @param level number strength of the wave
function EnemySystem:spawnWave(level)
    self.lastWaveLevel = level
    self.enemies = {}

    local baseHealth = 10
    local healthPerLevel = 2
    local baseDamage = 1
    local damagePerLevel = 1

    for i = 1, level do
        local enemy = createEnemy(
            baseHealth + healthPerLevel * level,
            baseDamage + damagePerLevel * level,
            {x = i, y = 0, z = 0}
        )
        table.insert(self.enemies, enemy)
    end
end

---Spawns a boss of the given type.
-- @param bossType string type identifier (e.g. "mini" or "boss")
function EnemySystem:spawnBoss(bossType)
    self.lastBossType = bossType
    self.enemies = {}

    local bossHealth = {
        mini = 50,
        boss = 100,
        location = 150
    }

    local bossDamage = {
        mini = 5,
        boss = 10,
        location = 15
    }

    local boss = createEnemy(
        bossHealth[bossType] or 20,
        bossDamage[bossType] or 2,
        {x = 0, y = 0, z = 0},
        bossType
    )

    table.insert(self.enemies, boss)
end

return EnemySystem
