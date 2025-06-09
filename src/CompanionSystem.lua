-- CompanionSystem.lua
-- Manages companions/pets and their upgrades

local CompanionSystem = {}
CompanionSystem.__index = CompanionSystem

---Creates a new companion system instance.
-- @return table
function CompanionSystem.new()
    return setmetatable({companions = {}}, CompanionSystem)
end

function CompanionSystem:add(companion)
    table.insert(self.companions, companion)
end

---Upgrades a companion if it provides an upgrade method.
-- @param index number Index of the companion to upgrade
-- @param amount number Amount of upgrade levels
function CompanionSystem:upgrade(index, amount)
    local companion = self.companions[index]
    if companion and type(companion.upgrade) == "function" then
        companion:upgrade(amount)
    end
end

return CompanionSystem
