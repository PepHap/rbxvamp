-- ThemeSystem.lua
-- Applies location-based color themes to UI elements

local ThemeSystem = {
    locationSystem = nil,
    current = nil,
    lastIndex = nil,
    lastLevel = nil,
}

local RunService = game:GetService("RunService")

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local ok, LightingSystem = pcall(function()
    return require(script.Parent:WaitForChild("LightingSystem"))
end)
if not ok then LightingSystem = nil end

local function multiplyColor(c, factor)
    if typeof and typeof(Color3) == "table" and typeof(c) == "Color3" then
        local clamp = math.clamp or function(v, lo, hi)
            if v < lo then return lo elseif v > hi then return hi else return v end
        end
        return Color3.new(
            clamp(c.R * factor, 0, 1),
            clamp(c.G * factor, 0, 1),
            clamp(c.B * factor, 0, 1)
        )
    elseif type(c) == "table" then
        local function clamp(v) return math.max(0, math.min(255, v)) end
        if c.r then
            return {r = clamp(c.r * factor), g = clamp(c.g * factor), b = clamp(c.b * factor)}
        end
    end
    return c
end

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
    local LevelSystem
    if RunService:IsServer() then
        LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
    else
        LevelSystem = require(script.Parent:WaitForChild("LevelSystem.client"))
    end
    local lvl = LevelSystem.currentLevel or 1
    if self.lastIndex == idx and self.lastLevel == lvl then return end
    self.lastIndex = idx
    self.lastLevel = lvl
    local loc = self.locationSystem:getCurrent()
    if loc then
        if loc.theme then
            local factor = 1 + (((lvl - 1) % 30) / 30) * 0.2
            local tinted = {}
            for k, v in pairs(loc.theme) do
                tinted[k] = multiplyColor(v, factor)
            end
            self:apply(tinted)
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
