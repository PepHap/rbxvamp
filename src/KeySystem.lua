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

return KeySystem
