-- DataPersistenceSystem.lua
-- Handles saving and loading player data using DataStoreService when available.

local RunService = game:GetService("RunService")
-- Only the server may access DataStoreService:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("DataPersistenceSystem should only be required on the server", 2)
    end
end

local src = script.Parent.Parent.Parent:WaitForChild("src")
local EnvironmentUtil = require(src:WaitForChild("EnvironmentUtil"))
local LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))
local DataPersistenceSystem = {
    ---When true and running inside Roblox, DataStoreService will be used.
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    ---DataStore instance when available.
    datastore = nil,
    ---DataStore name
    storeName = "PlayerData",
    ---Cached data tables by player id
    cache = {}
}

---Initializes the DataStore connection if possible.
function DataPersistenceSystem:start()
    if self.useRobloxObjects and RunService:IsServer() and game and type(game.GetService) == "function" then
        local ok, service = pcall(function()
            return game:GetService("DataStoreService")
        end)
        if ok and service then
            local success, store = pcall(function()
                return service:GetDataStore(self.storeName)
            end)
            if success then
                self.datastore = store
                if LoggingSystem and LoggingSystem.logAction then
                    LoggingSystem:logAction("datastore_connect", {store = self.storeName})
                end
            else
                if LoggingSystem and LoggingSystem.logAction then
                    LoggingSystem:logAction("datastore_error", {message = tostring(store)})
                end
            end
        end
    end
end

---Loads saved data for the given player id.
-- @param playerId string|number unique player identifier
-- @return table player data table
function DataPersistenceSystem:load(playerId)
    playerId = tostring(playerId)
    if self.cache[playerId] then
        return self.cache[playerId]
    end
    local data
    if RunService:IsServer() and self.datastore then
        local success, result = pcall(function()
            return self.datastore:GetAsync(playerId)
        end)
        if success and result then
            data = result
        elseif not success and LoggingSystem and LoggingSystem.logAction then
            LoggingSystem:logAction("datastore_get_fail", {player = playerId, error = tostring(result)})
        end
    end
    data = data or {}
    self.cache[playerId] = data
    if LoggingSystem and LoggingSystem.logAction then
        LoggingSystem:logAction("load", {player = playerId})
    end
    return data
end

---Saves data for the given player id.
-- @param playerId string|number unique player identifier
-- @param data table data to persist
function DataPersistenceSystem:save(playerId, data)
    playerId = tostring(playerId)
    self.cache[playerId] = data
    if RunService:IsServer() and self.datastore then
        local ok, err = pcall(function()
            self.datastore:SetAsync(playerId, data)
        end)
        if not ok and LoggingSystem and LoggingSystem.logAction then
            LoggingSystem:logAction("datastore_set_fail", {player = playerId, error = tostring(err)})
        end
    end
    if LoggingSystem and LoggingSystem.logAction then
        LoggingSystem:logAction("save", {player = playerId})
    end
end

return DataPersistenceSystem
