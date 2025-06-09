-- CompanionSystem.lua
-- Manages companions/pets and their upgrades

local CompanionSystem = {}

-- List of companion tables currently owned by the player. Each companion
-- stores a ``name``, ``rarity`` and current ``level``.
CompanionSystem.companions = {}

---Adds a companion to the player's roster. Missing ``level`` defaults to ``1``.
-- @param companion table
function CompanionSystem:add(companion)
    companion.level = companion.level or 1
    table.insert(self.companions, companion)
end

-- Removes a companion from the list by index
function CompanionSystem:removeCompanion(index)
    return table.remove(self.companions, index)
end

---Upgrades a companion's level when enough currency is supplied.
-- @param index number companion index within the list
-- @param amount number number of levels to add
-- @param currency number available upgrade currency
-- @return boolean ``true`` on success
function CompanionSystem:upgradeCompanion(index, amount, currency)
    local companion = self.companions[index]
    if not companion or currency < amount then
        return false
    end
    companion.level = companion.level + amount
    return true
end

return CompanionSystem
