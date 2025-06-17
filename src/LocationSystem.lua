-- LocationSystem.lua
-- Handles progression between different game areas.

local LocationSystem = {}

-- Load location data from assets so that stages can be configured externally.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")

-- Ordered list of locations including coordinates, level ranges and boss info.
LocationSystem.locations = require(assets:WaitForChild("locations"))

---Current location index in the locations table.
LocationSystem.currentIndex = 1

---Resets the location back to the first entry.
function LocationSystem:start()
    self.currentIndex = 1
end

---Returns the table for the current location.
function LocationSystem:getCurrent()
    return self.locations[self.currentIndex]
end

---Advances to the next location if one exists.
-- @return table location data after the advance
function LocationSystem:advance()
    if self.currentIndex < #self.locations then
        self.currentIndex = self.currentIndex + 1
    end
    return self:getCurrent()
end

return LocationSystem
