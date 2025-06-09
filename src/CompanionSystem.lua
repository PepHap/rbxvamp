-- CompanionSystem.lua
-- Manages companions/pets and their upgrades

local CompanionSystem = {}

CompanionSystem.companions = {}

function CompanionSystem:add(companion)
    table.insert(self.companions, companion)
end

function CompanionSystem:upgrade(companion, amount)
    -- TODO: upgrade companion using currency
end

return CompanionSystem
