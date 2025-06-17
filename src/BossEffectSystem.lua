-- BossEffectSystem.lua
-- Darkens the lighting when a boss spawns and restores it afterwards.

local BossEffectSystem = {
    active = false,
    original = nil,
    bossLighting = {
        ambient = Color3 and Color3.new(0.1, 0.1, 0.1) or {r=25,g=25,b=25},
        outdoorAmbient = Color3 and Color3.new(0.05, 0.05, 0.05) or {r=15,g=15,b=15},
        brightness = 1,
    },
    effect = nil,
}

local EventManager = require(script.Parent:WaitForChild("EventManager"))
local ok, LightingSystem = pcall(function()
    return require(script.Parent:WaitForChild("LightingSystem"))
end)
if not ok then LightingSystem = nil end

function BossEffectSystem:start()
    EventManager:Get("SpawnBoss"):Connect(function()
        BossEffectSystem:enable()
    end)
    EventManager:Get("SpawnWave"):Connect(function()
        BossEffectSystem:disable()
    end)
end

function BossEffectSystem:enable()
    if self.active or not LightingSystem then return end
    self.active = true
    self.original = LightingSystem.currentSettings
    LightingSystem.apply(self.bossLighting)
    self.effect = {glow = true}
end

function BossEffectSystem:disable()
    if not self.active then return end
    self.active = false
    if LightingSystem and self.original then
        LightingSystem.apply(self.original)
    end
    self.effect = nil
end

return BossEffectSystem
