-- ThemeSystem.lua
-- Applies location-based color themes to UI elements

local ThemeSystem = {
    locationSystem = nil,
    current = nil,
    lastIndex = nil,
}

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local ok, LightingSystem = pcall(function()
    return require(script.Parent:WaitForChild("LightingSystem"))
end)
if not ok then LightingSystem = nil end

local function applyColors(theme)
    if type(theme) ~= "table" then return end
    for k, v in pairs(theme) do
        UITheme.colors[k] = v
    end
end

function ThemeSystem:apply(theme)
    self.current = theme
    applyColors(theme)
    if LightingSystem and theme and theme.lighting then
        LightingSystem.apply(theme.lighting)
    end
    EventManager:Get("ThemeChanged"):Fire(theme)
end

function ThemeSystem:updateTheme()
    if not self.locationSystem then return end
    local idx = self.locationSystem.currentIndex
    if self.lastIndex == idx then return end
    self.lastIndex = idx
    local loc = self.locationSystem:getCurrent()
    if loc then
        if loc.theme then
            self:apply(loc.theme)
        end
        if LightingSystem and loc.lighting then
            LightingSystem.apply(loc.lighting)
        end
    end
end

function ThemeSystem:start(locationSystem)
    self.locationSystem = locationSystem or self.locationSystem or require(script.Parent:WaitForChild("LocationSystem"))
    self:updateTheme()
end

function ThemeSystem:update()
    self:updateTheme()
end

return ThemeSystem
