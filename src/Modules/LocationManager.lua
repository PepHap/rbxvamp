local LocationManager = {}
LocationManager.__index = LocationManager

local locations = {
    {Name = "Forest", RequiredLevel = 1},
    {Name = "Ruins", RequiredLevel = 5},
    {Name = "Cave", RequiredLevel = 10},
    {Name = "Castle", RequiredLevel = 20},
}

function LocationManager.new(playerManager)
    local self = setmetatable({}, LocationManager)
    self.PlayerManager = playerManager
    self.CurrentIndex = playerManager:GetLocation()
    return self
end

function LocationManager:UnlockNext()
    local nextIndex = self.CurrentIndex + 1
    local nextLoc = locations[nextIndex]
    if nextLoc and self.PlayerManager.Level >= nextLoc.RequiredLevel then
        self.CurrentIndex = nextIndex
        self.PlayerManager:SetLocation(nextIndex)
        return nextLoc.Name
    end
    return nil
end

function LocationManager:GetCurrent()
    return locations[self.CurrentIndex]
end

return LocationManager
