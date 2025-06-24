-- LoggingSystem.lua
-- Records server-side events like currency awards and item grants.
-- Logs are stored in memory for now but could be persisted via DataStoreService.

local RunService = game:GetService("RunService")
-- Logging should only occur on the server as recommended here:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("LoggingSystem should only be required on the server", 2)
    end
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local LoggingSystem = {
    logs = {},
    currencyLimit = 1000,
    rarityLimit = "SSS",
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    logDir = "server-log",
    logFile = "server-log/log.txt",
}

local HttpService
if LoggingSystem.useRobloxObjects then
    local ok, svc = pcall(function()
        return game:GetService("HttpService")
    end)
    if ok then
        HttpService = svc
    end
end

local function ensureFolder()
    if LoggingSystem.useRobloxObjects then
        return
    end
    if LoggingSystem._folderChecked then
        return
    end
    LoggingSystem._folderChecked = true
    local dir = LoggingSystem.logDir
    local ok, f = pcall(function()
        return io.open(dir .. "/.tmp", "w")
    end)
    if ok and f then
        f:close()
        os.remove(dir .. "/.tmp")
    else
        os.execute("mkdir -p " .. dir)
    end
end

local function writeLine(line)
    if LoggingSystem.useRobloxObjects then
        print("[ServerLog]", line)
        return
    end
    ensureFolder()
    local f = io.open(LoggingSystem.logFile, "a")
    if f then
        f:write(line, "\n")
        f:close()
    end
end

---Internal helper to append an entry to the log list.
local function addEntry(entry)
    table.insert(LoggingSystem.logs, entry)
end

---Logs a generic action and associated information.
--  This can be used by various systems to record notable events.
--  @param action string action identifier
--  @param info table details about the event
function LoggingSystem:logAction(action, info)
    local entry = {
        time = os.time(),
        action = action,
        info = info,
    }
    addEntry(entry)
    local line
    if HttpService and HttpService.JSONEncode then
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(entry)
        end)
        line = ok and encoded or (action .. " log")
    else
        line = action .. " " .. tostring(info)
    end
    writeLine(line)
end

---Logs a currency transaction.
-- @param playerId any identifier for the player
-- @param kind string currency type
-- @param amount number amount added or removed
function LoggingSystem:logCurrency(playerId, kind, amount)
    local amt = tonumber(amount) or 0
    local suspicious = math.abs(amt) > self.currencyLimit
    self:logAction("currency", {
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
    local suspicious = false
    if item and item.rarity then
        local limit = self.rarityLimit or "SSS"
        if item.rarity == limit then
            suspicious = true
        end
    end
    self:logAction("item", {
        player = playerId,
        action = action,
        id = item and item.id,
        rarity = item and item.rarity,
        level = item and item.level,
        suspicious = suspicious,
    })
end

---Logs when a player's position is corrected due to suspicious movement.
-- @param playerId any player identifier
-- @param from table previous position
-- @param to table new position
function LoggingSystem:logTeleport(playerId, from, to)
    self:logAction("teleport", {
        player = playerId,
        from = from,
        to = to,
    })
end

return LoggingSystem
