-- ItemSalvageSystem.lua
-- Allows salvaging equipment items into currency and crystals

local SalvageSystem = {}

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))

-- Base reward values per rarity. Values are multiplied by the item level
SalvageSystem.rarityValues = {
    C = {gold = 1, crystals = 0},
    D = {gold = 0, crystals = 0},
    B = {gold = 2, crystals = 1},
    A = {gold = 3, crystals = 2},
    S = {gold = 5, crystals = 3},
    SS = {gold = 8, crystals = 5},
    SSS = {gold = 15, crystals = 10},
}

---Salvages the given item granting currency based on rarity and level.
-- @param item table item entry
-- @return boolean success
function SalvageSystem:salvageItem(item)
    if type(item) ~= "table" then return false end
    local rarity = item.rarity or "C"
    local level = tonumber(item.level) or 1
    local vals = self.rarityValues[rarity]
    if not vals then return false end
    local gold = (vals.gold or 0) * level
    local crystals = (vals.crystals or 0) * level
    if gold > 0 then
        CurrencySystem:add("gold", gold)
    end
    if crystals > 0 then
        GachaSystem:addCrystals(crystals)
    end
    return true
end

---Salvages and removes an item from the inventory list.
-- @param itemSystem table ItemSystem instance
-- @param index number inventory index
-- @return boolean success
function SalvageSystem:salvageFromInventory(itemSystem, index)
    if type(itemSystem) ~= "table" or not itemSystem.removeItem then
        return false
    end
    local itm = itemSystem:removeItem(index)
    if not itm then return false end
    self:salvageItem(itm)
    return true
end

return SalvageSystem
