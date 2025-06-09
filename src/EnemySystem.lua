-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}

---Last level used when spawning a wave.
EnemySystem.lastWaveLevel = nil

---Last boss type that was spawned.
EnemySystem.lastBossType = nil

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
