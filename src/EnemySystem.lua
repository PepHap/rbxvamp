-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}

-- Multipliers applied to all enemy health and damage values. These start at
-- ``1`` so that base stats are unchanged until modified by other systems.
EnemySystem.healthScale = 1
EnemySystem.damageScale = 1


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

---Returns the nearest enemy to the given position.
-- @param position table with ``x`` and ``y`` keys
-- @return table|nil enemy table or ``nil`` when none exist
function EnemySystem:getNearestEnemy(position)
    local closest, minDistSq
    for _, enemy in ipairs(self.enemies) do
        -- Use the enemy's position field for distance calculations
        local dx = enemy.position.x - position.x
        local dy = enemy.position.y - position.y
        local distSq = dx * dx + dy * dy
        if not closest or distSq < minDistSq then
            closest = enemy
            minDistSq = distSq
        end
    end
    return closest
end

---Creates a wave of enemies scaled by the provided level.
-- @param level number strength of the wave
function EnemySystem:spawnWave(level)
    self.lastWaveLevel = level
    self.enemies = {}

    local baseHealth = 10
    local healthPerLevel = 2
    local baseDamage = 1
    local damagePerLevel = 1

    local hScale = self.healthScale or 1
    local dScale = self.damageScale or 1

    for i = 1, level do
        local enemy = createEnemy(
            (baseHealth + healthPerLevel * level) * hScale,
            (baseDamage + damagePerLevel * level) * dScale,
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

    local hScale = self.healthScale or 1
    local dScale = self.damageScale or 1

    local boss = createEnemy(
        (bossHealth[bossType] or 20) * hScale,
        (bossDamage[bossType] or 2) * dScale,
        {x = 0, y = 0, z = 0},
        bossType
    )

    table.insert(self.enemies, boss)
end

return EnemySystem
