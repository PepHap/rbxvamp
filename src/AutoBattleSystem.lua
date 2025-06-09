-- AutoBattleSystem.lua
-- Provides automatic combat actions when enabled.

local AutoBattleSystem = {}

-- Resolve the EnemySystem path relative to how this module was required. This
-- keeps unit tests functional even when they load modules using relative paths
-- like "../src/AutoBattleSystem".
local moduleName = (...)
local prefix = "src."
if type(moduleName) == "string" then
    prefix = moduleName:gsub("AutoBattleSystem$", "")
end
local EnemySystem = require(prefix .. "EnemySystem")

---Current player position used for simple movement calculations.
AutoBattleSystem.playerPosition = {x = 0, y = 0}

---Movement speed in studs per second used when approaching a target.
AutoBattleSystem.moveSpeed = 1

---Maximum distance at which an attack will occur instead of moving.
AutoBattleSystem.attackRange = 5

---Reference to the last enemy attacked by the system.
AutoBattleSystem.lastAttackTarget = nil

---Indicates whether auto-battle mode is active.
AutoBattleSystem.enabled = false

---Enables auto-battle mode.
function AutoBattleSystem:enable()
    self.enabled = true
end

---Disables auto-battle mode.
function AutoBattleSystem:disable()
    self.enabled = false
end

---Updates automatic combat behavior when enabled.
-- @param dt number delta time since last update
function AutoBattleSystem:update(dt)
    if not self.enabled then
        return
    end
    local pos = self.playerPosition
    local target = EnemySystem:getNearestEnemy(pos)
    if not target then
        return
    end

    -- Target tables store coordinates within the `position` field
    local dx = target.position.x - pos.x
    local dy = target.position.y - pos.y
    local distSq = dx * dx + dy * dy
    if distSq <= self.attackRange * self.attackRange then
        -- Target is within attack range, register an attack
        self.lastAttackTarget = target
    else
        -- Move toward the target by a small step based on moveSpeed
        local dist = math.sqrt(distSq)
        if dist > 0 then
            local step = math.min(self.moveSpeed * dt, dist)
            pos.x = pos.x + dx / dist * step
            pos.y = pos.y + dy / dist * step
        end
        self.lastAttackTarget = nil
    end
end

return AutoBattleSystem
