-- InventoryModule.lua
-- Simple wrapper around ItemSystem providing convenience methods for the UI

local InventoryModule = {}
InventoryModule.__index = InventoryModule

local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
local ItemSalvageSystem = require(script.Parent:WaitForChild("ItemSalvageSystem"))

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

---Equips an item from the inventory list into the given slot.
-- @param index number inventory index
-- @param slot string equipment slot
function InventoryModule:EquipFromInventory(index, slot)
    return self.itemSystem:equipFromInventory(index, slot)
end

---Unequips an item from the slot and stores it in the inventory.
-- @param slot string equipment slot
-- @return table|nil removed item
function InventoryModule:UnequipToInventory(slot)
    return self.itemSystem:unequipToInventory(slot)
end

---Retrieves a page of items from the inventory.
-- @param page number page index starting at 1
-- @param perPage number items per page
-- @return table list of item entries
function InventoryModule:GetInventoryPage(page, perPage)
    return self.itemSystem:getInventoryPage(page, perPage)
end

---Returns the number of inventory pages for the given size.
-- @param perPage number items per page
-- @return number page count
function InventoryModule:GetInventoryPageCount(perPage)
    return self.itemSystem:getInventoryPageCount(perPage)
end

---Upgrades the item in the specified slot when enough currency is available.
-- @param slot string equipment slot
-- @param amount number number of levels to add
-- @param currencyType string currency identifier
-- @return boolean success
function InventoryModule:UpgradeItem(slot, amount, currencyType)
    return self.itemSystem:upgradeItem(slot, amount, currencyType)
end

---Salvages an item from the inventory into currency and crystals.
-- @param index number inventory index
-- @return boolean success
function InventoryModule:SalvageInventoryItem(index)
    return ItemSalvageSystem:salvageFromInventory(self.itemSystem, index)
end

---Salvages an equipped item from the specified slot.
-- @param slot string equipment slot name
-- @return boolean success
function InventoryModule:SalvageEquippedItem(slot)
    return ItemSalvageSystem:salvageFromSlot(self.itemSystem, slot)
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
        if itm then
            local statsTbl = ItemSystem.getItemStats(itm)
            for k, v in pairs(statsTbl) do
                combined[k] = (combined[k] or 0) + v
            end
        end
    end
    return combined
end

return InventoryModule

