-- CrystalExchangeSystem.lua
-- Allows spending crystals for tickets or currency

local CrystalExchangeSystem = {}

local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

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
    if (GachaSystem.crystals or 0) < total then
        return false
    end
    GachaSystem.crystals = GachaSystem.crystals - total
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
    if (GachaSystem.crystals or 0) < total then
        return false
    end
    GachaSystem.crystals = GachaSystem.crystals - total
    CurrencySystem:add(kind, n)
    return true
end

return CrystalExchangeSystem
