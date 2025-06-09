-- GameManager.lua
-- Central game management module
-- Handles initialization and main game loop

local GameManager = {}
GameManager.__index = GameManager

---Creates a new game manager instance.
-- @return table
function GameManager.new()
    return setmetatable({running = false}, GameManager)
end

function GameManager:start()
    self.running = true
    -- TODO: initialize game state
end

function GameManager:update(dt)
    if not self.running then
        return
    end
    -- TODO: update game logic every frame
end

return GameManager
