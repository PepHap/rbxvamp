-- rotate_events.lua
-- increments version numbers in src/RemoteEventNames.lua

local path = "src/RemoteEventNames.lua"
local f = assert(io.open(path, "r"))
local content = f:read("*a")
f:close()

local current = content:match("_v(%d+)")
if not current then
    error("no version number found")
end
local next = tonumber(current) + 1
local newContent = content:gsub("_v"..current, "_v"..next)

local out = assert(io.open(path, "w"))
out:write(newContent)
out:close()

print("RemoteEvent names rotated to version v"..next)
