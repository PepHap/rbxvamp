-- EventManager.lua
-- Lightweight event dispatcher used by various systems

local EventManager = {}

-- Internal registry mapping event names to dispatcher objects
EventManager.events = {}

---Retrieves an event dispatcher, creating it if necessary.
-- Each dispatcher exposes ``Connect`` and ``Fire`` methods similar to
-- Roblox's ``BindableEvent`` interface for compatibility. Additional
-- helper aliases ``FireClient`` and ``FireAllClients`` are provided
-- so the same code can run both on the server and client.
-- @param name string event identifier
-- @return table dispatcher with ``Connect`` and ``Fire`` functions
function EventManager:Get(name)
    local ev = self.events[name]
    if ev then
        return ev
    end
    local callbacks = {}
    ev = {
        Connect = function(_, fn)
            table.insert(callbacks, fn)
        end,
        Fire = function(_, ...)
            for _, fn in ipairs(callbacks) do
                fn(...)
            end
        end,
        -- Aliases used by code expecting Roblox RemoteEvents
        FireClient = function(self, ...)
            self:Fire(...)
        end,
        FireAllClients = function(self, ...)
            self:Fire(...)
        end,
        OnServerEvent = {Connect = function(_, fn)
            table.insert(callbacks, fn)
        end},
        OnClientEvent = {Connect = function(_, fn)
            table.insert(callbacks, fn)
        end},
    }
    self.events[name] = ev
    return ev
end

return EventManager
