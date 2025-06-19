-- CompanionSystem.lua
-- Manages companions/pets and their upgrades

local CompanionSystem = {}

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

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

---Upgrades a companion's level by spending Ether.
-- @param index number companion index within the list
-- @param amount number number of levels to add
-- @return boolean ``true`` on success
function CompanionSystem:upgradeCompanion(index, amount)
    local companion = self.companions[index]
    if not companion then
        return false
    end
    local n = tonumber(amount)
    if not n or n <= 0 then
        return false
    end
    if not CurrencySystem:spend("ether", n) then
        return false
    end
    companion.level = companion.level + n
    return true
end

---Serializes all owned companions.
function CompanionSystem:saveData()
    local out = {}
    for i, c in ipairs(self.companions) do
        out[i] = {name = c.name, rarity = c.rarity, level = c.level}
    end
    return out
end

---Loads companion data from a previously saved table.
-- @param data table list of companions
function CompanionSystem:loadData(data)
    self.companions = {}
    if type(data) ~= "table" then
        return
    end
    for _, c in ipairs(data) do
        table.insert(self.companions, {
            name = c.name,
            rarity = c.rarity,
            level = c.level or 1,
        })
    end
end

return CompanionSystem
