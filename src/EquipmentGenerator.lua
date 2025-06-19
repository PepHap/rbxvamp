-- EquipmentGenerator.lua
-- Utility for selecting random equipment items by slot and rarity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local itemPool = require(assets:WaitForChild("items"))

local EquipmentGenerator = {}

---Selects a random item matching the provided slot and rarity.
-- If no item matches the rarity, a random item for the slot is returned.
-- @param slot string equipment slot
-- @param rarity string|nil desired rarity
-- @param pool table|nil custom item pool
-- @return table|nil item definition
function EquipmentGenerator.getRandomItem(slot, rarity, pool)
    pool = pool or itemPool
    local items = pool[slot]
    if not items or #items == 0 then
        return nil
    end
    local candidates = {}
    if rarity then
        for _, itm in ipairs(items) do
            if itm.rarity == rarity then
                table.insert(candidates, itm)
            end
        end
    end
    if #candidates == 0 then
        candidates = items
    end
    return candidates[math.random(#candidates)]
end

return EquipmentGenerator
