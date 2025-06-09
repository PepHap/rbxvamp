-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}

---List of active enemy instances with ``x`` and ``y`` coordinates.
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
        local dx = enemy.x - position.x
        local dy = enemy.y - position.y
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
    -- TODO: actual enemy spawn logic
end

---Spawns a boss of the given type.
-- @param bossType string type identifier (e.g. "mini" or "boss")
function EnemySystem:spawnBoss(bossType)
    self.lastBossType = bossType
    -- TODO: actual boss spawn logic
end

return EnemySystem
