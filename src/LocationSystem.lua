-- LocationSystem.lua
-- Handles progression between different game areas.

local LocationSystem = {}
local PlayerLevelSystem

-- Load location data from assets so that stages can be configured externally.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))

-- Ordered list of locations including coordinates, level ranges and boss info.
LocationSystem.locations = ModuleUtil.loadAssetModule("locations") or {}

---Current location index in the locations table.
LocationSystem.currentIndex = 1

---Resets the location back to the first entry.
function LocationSystem:start()
    PlayerLevelSystem = PlayerLevelSystem or require(script.Parent:WaitForChild("PlayerLevelSystem"))
    self.currentIndex = 1
end

---Returns the table for the current location.
function LocationSystem:getCurrent()
    return self.locations[self.currentIndex]
end

---Returns true when the location at ``index`` is unlocked for ``level``.
-- @param index number location array index
-- @param level number? player level
function LocationSystem:isUnlocked(index, level)
    local loc = self.locations[index]
    if not loc then return false end
    PlayerLevelSystem = PlayerLevelSystem or require(script.Parent:WaitForChild("PlayerLevelSystem"))
    local lvl = tonumber(level) or PlayerLevelSystem.level or 1
    return lvl >= (loc.levelStart or 1)
end

---Advances to the next location if one exists.
-- @return table location data after the advance
function LocationSystem:advance()
    PlayerLevelSystem = PlayerLevelSystem or require(script.Parent:WaitForChild("PlayerLevelSystem"))
    local nextIndex = self.currentIndex + 1
    if nextIndex <= #self.locations and self:isUnlocked(nextIndex, PlayerLevelSystem.level) then
        self.currentIndex = nextIndex
    end
    return self:getCurrent()
end

return LocationSystem
