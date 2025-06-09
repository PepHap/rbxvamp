-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}

---Base stats used for enemies at level 1.
EnemySystem.baseHealth = 100
EnemySystem.baseDamage = 10

---Current enemy health after scaling.
EnemySystem.enemyHealth = EnemySystem.baseHealth

---Current enemy damage after scaling.
EnemySystem.enemyDamage = EnemySystem.baseDamage

---Last level used when spawning a wave.
EnemySystem.lastWaveLevel = nil

---Stats recorded for the last spawned wave.
EnemySystem.lastWaveStats = nil

---Last boss type that was spawned.
EnemySystem.lastBossType = nil

---Stats recorded for the last spawned boss.
EnemySystem.lastBossStats = nil

---Creates a wave of enemies scaled by the provided level.
-- @param level number strength of the wave
function EnemySystem:spawnWave(level)
    self.lastWaveLevel = level
    self.lastWaveStats = {health = self.enemyHealth, damage = self.enemyDamage}
    -- TODO: actual enemy spawn logic
end

---Spawns a boss of the given type.
-- @param bossType string type identifier (e.g. "mini" or "boss")
function EnemySystem:spawnBoss(bossType)
    self.lastBossType = bossType
    self.lastBossStats = {health = self.enemyHealth, damage = self.enemyDamage}
    -- TODO: actual boss spawn logic
end

---Resets enemy stats to base values. Useful for tests.
function EnemySystem:reset()
    self.enemyHealth = self.baseHealth
    self.enemyDamage = self.baseDamage
    self.lastWaveStats = nil
    self.lastBossStats = nil
end

return EnemySystem
