-- CompanionSystem.lua
-- Manages companions/pets and their upgrades

local CompanionSystem = {}

CompanionSystem.companions = {}

function CompanionSystem:add(companion)
    table.insert(self.companions, companion)
end

-- Removes a companion from the list by index
function CompanionSystem:removeCompanion(index)
    return table.remove(self.companions, index)
end

function CompanionSystem:upgrade(companion, amount)
    -- TODO: upgrade companion using currency
end

return CompanionSystem
