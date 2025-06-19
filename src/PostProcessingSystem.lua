-- PostProcessingSystem.lua
-- Applies simple color correction effects and reacts to boss events.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local PostProcessingSystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    colorEffect = nil,
    bossTint = Color3 and Color3.new(1, 0.9, 0.9) or {r=255,g=230,b=230},
    normalTint = Color3 and Color3.new(1,1,1) or {r=255,g=255,b=255},
}

local EventManager = require(script.Parent:WaitForChild("EventManager"))

local function ensureEffect()
    if not PostProcessingSystem.useRobloxObjects then
        PostProcessingSystem.colorEffect = PostProcessingSystem.colorEffect or {}
        return PostProcessingSystem.colorEffect
    end
    if not PostProcessingSystem.colorEffect then
        local ok, Lighting = pcall(function()
            return game:GetService("Lighting")
        end)
        if ok and Lighting and Instance and type(Instance.new) == "function" then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Parent = Lighting
            PostProcessingSystem.colorEffect = cc
        end
    end
    return PostProcessingSystem.colorEffect
end

function PostProcessingSystem:applyTint(tint)
    local effect = ensureEffect()
    if not effect then return end
    if effect.TintColor ~= nil then
        effect.TintColor = tint
    else
        effect.TintColor = tint
    end
end

function PostProcessingSystem:onBoss(start)
    if start then
        self:applyTint(self.bossTint)
    else
        self:applyTint(self.normalTint)
    end
end

function PostProcessingSystem:start()
    EventManager:Get("SpawnBoss"):Connect(function()
        PostProcessingSystem:onBoss(true)
    end)
    EventManager:Get("SpawnWave"):Connect(function()
        PostProcessingSystem:onBoss(false)
    end)
end

return PostProcessingSystem
