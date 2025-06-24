-- ClientGameManager.lua
-- Provides a client-safe interface that excludes server-only methods.

local GameManager = require(script.Parent:WaitForChild("GameManager"))

-- The GameManager module now excludes privileged methods entirely when
-- replicated to the client. Simply return the shared table as-is.

return GameManager
