-- InventoryModule.lua
-- Simple wrapper around ItemSystem providing convenience methods for the UI

local InventoryModule = {}
InventoryModule.__index = InventoryModule

local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))

---Creates a new InventoryModule instance.
-- @param statSystem table optional stat system for base stats
function InventoryModule.new(statSystem)
    local self = setmetatable({}, InventoryModule)
    self.itemSystem = ItemSystem.new()
    self.statSystem = statSystem or StatUpgradeSystem
    return self
end

---Adds an item table to the inventory.
function InventoryModule:AddItem(itemInfo)
    self.itemSystem:addItem(itemInfo)
end

---Equips an item table directly into the slot.
function InventoryModule:EquipItem(slot, itemInfo)
    self.itemSystem:equip(slot, itemInfo)
end

---Unequips and returns the item from the slot.
function InventoryModule:RemoveItem(slot)
    return self.itemSystem:unequip(slot)
end

---Returns a table of combined stats from base values and equipped items.
function InventoryModule:GetStats()
    local combined = {}
    local stats = self.statSystem
    if stats and stats.stats then
        for name, data in pairs(stats.stats) do
            combined[name] = (data.base or 0) * (data.level or 1)
        end
    end
    for _, itm in pairs(self.itemSystem.slots) do
        if itm and itm.stats then
            for k, v in pairs(itm.stats) do
                combined[k] = (combined[k] or 0) + v
            end
        end
    end
    return combined
end

return InventoryModule

