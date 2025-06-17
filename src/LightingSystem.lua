-- LightingSystem.lua
-- Adjusts environment lighting based on the current location theme

local LightingSystem = {
    useRobloxObjects = false,
    locationSystem = nil,
    currentSettings = nil,
}

local EventManager = require(script.Parent:WaitForChild("EventManager"))

local function applyLighting(settings)
    if not settings then return end
    LightingSystem.currentSettings = settings
    if LightingSystem.useRobloxObjects and game and game:GetService then
        local Lighting = game:GetService("Lighting")
        if Lighting then
            if settings.ambient then Lighting.Ambient = settings.ambient end
            if settings.outdoorAmbient then Lighting.OutdoorAmbient = settings.outdoorAmbient end
            if settings.brightness then Lighting.Brightness = settings.brightness end
        end
    end
    EventManager:Get("LightingChanged"):Fire(settings)
end

function LightingSystem:updateLighting()
    local loc = self.locationSystem and self.locationSystem:getCurrent()
    if not loc or self.currentSettings == loc.lighting then return end
    applyLighting(loc.lighting)
end

function LightingSystem:start(locationSystem)
    self.locationSystem = locationSystem or self.locationSystem or require(script.Parent:WaitForChild("LocationSystem"))
    self:updateLighting()
end

function LightingSystem:update()
    self:updateLighting()
end

LightingSystem.apply = applyLighting

return LightingSystem
