-- RegenSystem.lua
-- Applies health and mana regeneration each frame based on StatUpgradeSystem.

local RegenSystem = {}

local RunService = game:GetService("RunService")

local server = script.Parent
local src = script.Parent.Parent.Parent:WaitForChild("src")

local PlayerSystem
if RunService:IsServer() then
    PlayerSystem = require(script.Parent.Parent:WaitForChild("ServerPlayerSystem"))
else
    PlayerSystem = require(src:WaitForChild("PlayerSystem"))
end
local SkillCastSystem = require(server:WaitForChild("SkillCastSystem"))
local StatUpgradeSystem = require(src:WaitForChild("StatUpgradeSystem"))

---Applies regeneration values every update.
-- @param dt number delta time
function RegenSystem:update(dt)
    local stats = StatUpgradeSystem.stats
    if not stats then return end
    local hpStat = stats.HealthRegen
    if hpStat and PlayerSystem.heal then
        local rate = (hpStat.base or 0) * (hpStat.level or 1)
        if rate > 0 then
            PlayerSystem:heal(rate * dt)
        end
    end
    local manaStat = stats.MaxMana
    if manaStat then
        SkillCastSystem.maxMana = (manaStat.base or 0) * (manaStat.level or 1)
    end
    local mrStat = stats.ManaRegen
    if mrStat then
        SkillCastSystem.regenRate = (mrStat.base or 0) * (mrStat.level or 1)
    end
end

return RegenSystem
