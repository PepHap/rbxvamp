-- AutoBattleSystem.lua
-- Provides automatic combat actions when enabled.

local AutoBattleSystem = {}

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
    -- TODO: perform automatic actions such as attacking enemies
end

return AutoBattleSystem
