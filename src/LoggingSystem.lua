-- LoggingSystem.lua
-- Records server-side events like currency awards and item grants.
-- Logs are stored in memory for now but could be persisted via DataStoreService.

local LoggingSystem = {
    logs = {},
    currencyLimit = 1000,
}

---Internal helper to append an entry to the log list.
local function addEntry(action, info)
    table.insert(LoggingSystem.logs, {
        time = os.time(),
        action = action,
        info = info,
    })
end

---Logs a currency transaction.
-- @param playerId any identifier for the player
-- @param kind string currency type
-- @param amount number amount added or removed
function LoggingSystem:logCurrency(playerId, kind, amount)
    local amt = tonumber(amount) or 0
    local suspicious = math.abs(amt) > self.currencyLimit
    addEntry("currency", {
        player = playerId,
        kind = kind,
        amount = amt,
        suspicious = suspicious,
    })
end

---Logs when an item is granted to a player.
-- @param playerId any player identifier
-- @param item table item table
-- @param action string description of the action
function LoggingSystem:logItem(playerId, item, action)
    addEntry("item", {
        player = playerId,
        action = action,
        id = item and item.id,
        rarity = item and item.rarity,
        level = item and item.level,
    })
end

return LoggingSystem
