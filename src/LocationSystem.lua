-- LocationSystem.lua
-- Handles progression between different game areas.

local LocationSystem = {}

-- Ordered list of locations. Each entry may include a unique currency type
-- or other metadata associated with that area.
LocationSystem.locations = {
    {
        name = "Meadow",
        currency = "gold",
        theme = {
            windowBackground = {r = 25, g = 40, b = 25},
            buttonBackground = {r = 60, g = 90, b = 60},
            buttonHover = {r = 80, g = 120, b = 80},
        },
    },
    {
        name = "Dungeon",
        currency = "ore",
        theme = {
            windowBackground = {r = 30, g = 30, b = 45},
            buttonBackground = {r = 80, g = 50, b = 50},
            buttonHover = {r = 100, g = 70, b = 70},
        },
    },
    {
        name = "Ruins",
        currency = "crystal",
        theme = {
            windowBackground = {r = 45, g = 35, b = 25},
            buttonBackground = {r = 110, g = 70, b = 40},
            buttonHover = {r = 130, g = 90, b = 60},
        },
    },
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
