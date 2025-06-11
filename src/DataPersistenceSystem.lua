-- DataPersistenceSystem.lua
-- Handles saving and loading player data using DataStoreService when available.

local DataPersistenceSystem = {
    ---When true and running inside Roblox, DataStoreService will be used.
    useRobloxObjects = false,
    ---DataStore instance when available.
    datastore = nil,
    ---DataStore name
    storeName = "PlayerData",
    ---Cached data tables by player id
    cache = {}
}

---Initializes the DataStore connection if possible.
function DataPersistenceSystem:start()
    if self.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, service = pcall(function()
            return game:GetService("DataStoreService")
        end)
        if ok and service then
            local success, store = pcall(function()
                return service:GetDataStore(self.storeName)
            end)
            if success then
                self.datastore = store
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
    if self.datastore then
        local success, result = pcall(function()
            return self.datastore:GetAsync(playerId)
        end)
        if success and result then
            data = result
        end
    end
    data = data or {}
    self.cache[playerId] = data
    return data
end

---Saves data for the given player id.
-- @param playerId string|number unique player identifier
-- @param data table data to persist
function DataPersistenceSystem:save(playerId, data)
    playerId = tostring(playerId)
    self.cache[playerId] = data
    if self.datastore then
        pcall(function()
            self.datastore:SetAsync(playerId, data)
        end)
    end
end

return DataPersistenceSystem
