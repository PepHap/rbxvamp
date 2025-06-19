-- BossEffectSystem.lua
-- Darkens the lighting when a boss spawns and restores it afterwards.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local BossEffectSystem = {
    active = false,
    original = nil,
    bossLighting = {
        ambient = Color3 and Color3.new(0.1, 0.1, 0.1) or {r=25,g=25,b=25},
        outdoorAmbient = Color3 and Color3.new(0.05, 0.05, 0.05) or {r=15,g=15,b=15},
        brightness = 1,
    },
    effect = nil,
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    particle = nil,
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
    if self.useRobloxObjects and game and typeof and typeof(Instance.new)=="function" then
        local ok, ws = pcall(function() return game:GetService("Workspace") end)
        if ok and ws then
            local part = Instance.new("Part")
            part.Anchored = true
            part.Transparency = 1
            part.CanCollide = false
            part.Position = Vector3.new(0, 0, 0)
            part.Parent = ws
            local emitter = Instance.new("ParticleEmitter")
            emitter.Rate = 50
            emitter.Color = ColorSequence.new(Color3.new(1,1,0))
            emitter.Parent = part
            self.particle = part
        end
    else
        self.particle = {particle = true}
    end
end

function BossEffectSystem:disable()
    if not self.active then return end
    self.active = false
    if LightingSystem and self.original then
        LightingSystem.apply(self.original)
    end
    self.effect = nil
    if self.particle then
        if self.useRobloxObjects and self.particle.Destroy then
            self.particle:Destroy()
        end
        self.particle = nil
    end
end

return BossEffectSystem
