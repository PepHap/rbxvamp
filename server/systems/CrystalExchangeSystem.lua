-- CrystalExchangeSystem.lua
-- Allows spending crystals for tickets or currency

local RunService = game:GetService("RunService")
if RunService and RunService.IsClient and RunService:IsClient() then
    error("CrystalExchangeSystem should only be required on the server", 2)
end

local CrystalExchangeSystem = {}

local src = script.Parent.Parent.Parent:WaitForChild("src")

local GachaSystem = require(src:WaitForChild("GachaSystem"))
local CurrencySystem = require(src:WaitForChild("CurrencySystem"))

---Cost in crystals per ticket type
CrystalExchangeSystem.ticketPrices = {
    skill = 1,
    companion = 1,
    equipment = 1,
}

---Cost in crystals per unit of upgrade currency
CrystalExchangeSystem.currencyPrices = {
    gold = 1,
    ore = 1,
    ether = 1,
    crystal = 1,
}

---Purchases gacha tickets using crystals.
-- @param kind string ticket type
-- @param amount number quantity of tickets
-- @return boolean success
function CrystalExchangeSystem:buyTickets(kind, amount)
    local price = self.ticketPrices[kind]
    local n = tonumber(amount) or 1
    if not price or n <= 0 then
        return false
    end
    local total = price * n
    if not GachaSystem:spendCrystals(total) then
        return false
    end
    GachaSystem.tickets[kind] = (GachaSystem.tickets[kind] or 0) + n
    return true
end

---Purchases upgrade currency using crystals.
-- @param kind string currency type
-- @param amount number quantity
-- @return boolean success
function CrystalExchangeSystem:buyCurrency(kind, amount)
    local price = self.currencyPrices[kind]
    local n = tonumber(amount) or 1
    if not price or n <= 0 then
        return false
    end
    local total = price * n
    if not GachaSystem:spendCrystals(total) then
        return false
    end
    CurrencySystem:add(kind, n)
    return true
end

---Upgrades an item directly using crystals.
-- Converts the required upgrade currency into crystals and performs the upgrade.
-- @param itemSystem table item system instance
-- @param slot string equipment slot name
-- @param amount number levels to upgrade
-- @param currencyType string currency used for the upgrade cost
-- @return boolean success
function CrystalExchangeSystem:upgradeItemWithCrystals(itemSystem, slot, amount, currencyType)
    currencyType = currencyType or "gold"
    local price = self.currencyPrices[currencyType]
    if not price or type(itemSystem) ~= "table" then
        return false
    end
    local item = itemSystem.slots[slot]
    local n = tonumber(amount) or 1
    if not item or n <= 0 then
        return false
    end

    local current = item.level or 1
    local target = math.min(itemSystem.maxLevel, current + n)
    if target <= current then
        return false
    end

    local currencyNeeded = 0
    for lvl = current + 1, target do
        currencyNeeded = currencyNeeded + (itemSystem.upgradeCosts[lvl] or 0)
    end

    local crystalCost = currencyNeeded * price
    if not GachaSystem:spendCrystals(crystalCost) then
        return false
    end
    CurrencySystem:add(currencyType, currencyNeeded)
    local ok = itemSystem:upgradeItem(slot, target - current, currencyType)
    return ok
end

---Price in crystals when selling equipment by rarity
CrystalExchangeSystem.sellPrices = {
    C = 1,
    D = 1,
    B = 3,
    A = 5,
    S = 10,
    SS = 20,
    SSS = 50,
}

---Sells an inventory item for crystals.
-- @param itemSystem table item system instance
-- @param index number inventory index to sell
-- @return boolean success
function CrystalExchangeSystem:sellInventoryItem(itemSystem, index)
    if type(itemSystem) ~= "table" then
        return false
    end
    local item = itemSystem:removeItem(index)
    if not item then
        return false
    end
    local rarity = item.rarity
    local reward = self.sellPrices[rarity] or 0
    GachaSystem:addCrystals(reward)
    return true
end

---Sells an equipped item from a slot for crystals.
-- @param itemSystem table item system instance
-- @param slot string equipment slot to sell
-- @return boolean success
function CrystalExchangeSystem:sellEquippedItem(itemSystem, slot)
    if type(itemSystem) ~= "table" or not itemSystem.unequip then
        return false
    end
    local item = itemSystem:unequip(slot)
    if not item then
        return false
    end
    local rarity = item.rarity
    local reward = self.sellPrices[rarity] or 0
    GachaSystem:addCrystals(reward)
    return true
end

return CrystalExchangeSystem
