-- GameManager.lua
-- Central game management module
-- Handles initialization and main game loop

--[[
    GameManager.lua
    Central management module responsible for initializing and
    updating registered game systems.

    Systems can be any table that optionally exposes ``start`` and
    ``update`` methods. Systems are stored by name for easy retrieval.
--]]

local GameManager = {
    -- Mapping of system name to implementation
    systems = {},
    -- Ordered list of system names for deterministic iteration
    order = {}
}

--- Registers a system for later initialization and updates.
-- @param name string unique key for the system
-- @param system table table implementing optional start/update methods
function GameManager:addSystem(name, system)
    assert(name ~= nil, "System name must be provided")
    assert(system ~= nil, "System table must be provided")
    self.systems[name] = system
    table.insert(self.order, name)
end

function GameManager:start()
    -- Initialize all registered systems in the order they were added
    for _, name in ipairs(self.order) do
        local system = self.systems[name]
        if type(system.start) == "function" then
            system:start()
        end
    end
end

function GameManager:update(dt)
    -- Forward the update call to every registered system
    for _, name in ipairs(self.order) do
        local system = self.systems[name]
        if type(system.update) == "function" then
            system:update(dt)
        end
    end
end

-- Integrate the default enemy system on load
local EnemySystem = require("src.EnemySystem")
GameManager:addSystem("Enemy", EnemySystem)

-- Auto battle functionality can optionally control the player's actions
local AutoBattleSystem = require("src.AutoBattleSystem")
GameManager:addSystem("AutoBattle", AutoBattleSystem)

return GameManager
