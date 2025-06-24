-- ServerGameManager.lua
-- Provides access to the full GameManager implementation on the server.

-- The server requires the complete GameManager with privileged methods.
-- Clients should never require this module directly. Instead they must use
-- ``ClientGameManager`` which removes server-only functionality. See Roblox
-- networking guidelines:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer

local GameManager = require(script.Parent:WaitForChild("GameManager"))

return GameManager

