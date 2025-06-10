-- LocationSystem.lua
-- Handles progression between different game areas.

local LocationSystem = {}

-- Ordered list of locations. Each entry may include a unique currency type
-- or other metadata associated with that area.
LocationSystem.locations = {
    {name = "Meadow", currency = "gold"},
    {name = "Dungeon", currency = "ore"},
    {name = "Ruins", currency = "crystal"},
}

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
