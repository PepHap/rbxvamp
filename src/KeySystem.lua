-- KeySystem.lua
-- Tracks counts of different key types used for accessing special content.

local KeySystem = {}

---Table storing current key counts keyed by kind.
KeySystem.keys = {}

---Adds keys of a specific type.
-- @param kind string type of key (e.g. "arena", "skill")
-- @param amount number amount to add, defaults to 1
function KeySystem:addKey(kind, amount)
    local n = tonumber(amount) or 1
    if n <= 0 then
        return
    end
    self.keys[kind] = (self.keys[kind] or 0) + n
end

---Attempts to consume one key of the given type.
-- @param kind string type of key
-- @return boolean true when a key was spent
function KeySystem:useKey(kind)
    local count = self.keys[kind] or 0
    if count > 0 then
        self.keys[kind] = count - 1
        return true
    end
    return false
end

---Returns the current count for a key type.
-- @param kind string key type
-- @return number
function KeySystem:getCount(kind)
    return self.keys[kind] or 0
end

---Serializes key counts for saving between sessions.
-- @return table mapping of key types to counts
function KeySystem:saveData()
    local data = {}
    for k, v in pairs(self.keys) do
        data[k] = v
    end
    return data
end

---Restores key counts from the provided table.
-- @param data table previously saved via ``saveData``
function KeySystem:loadData(data)
    self.keys = {}
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        self.keys[k] = v
    end
end

return KeySystem
