-- SetBonusSystem.lua
-- Determines active equipment set bonuses.

local SetBonusSystem = {
    itemSystem = nil,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
SetBonusSystem.sets = require(assets:WaitForChild("set_bonuses"))

---Returns a list of bonus tables for all active sets.
function SetBonusSystem:getActiveBonuses()
    local bonuses = {}
    local items = self.itemSystem and self.itemSystem.slots or {}
    for _, set in ipairs(self.sets) do
        local ok = true
        for slot, name in pairs(set.requirements) do
            if not items[slot] or items[slot].name ~= name then
                ok = false
                break
            end
        end
        if ok then
            table.insert(bonuses, set.bonus)
        end
    end
    return bonuses
end

---Applies active bonuses to the provided stat table.
-- @param stats table stats to modify
function SetBonusSystem:applyBonuses(stats)
    local bonuses = self:getActiveBonuses()
    for _, bonus in ipairs(bonuses) do
        for k, v in pairs(bonus) do
            stats[k] = (stats[k] or 0) + v
        end
    end
    return stats
end

return SetBonusSystem
