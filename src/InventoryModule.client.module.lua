-- InventoryModule.client.module.lua
-- Client-side inventory wrapper without server-only features.

local InventoryModule = {}
InventoryModule.__index = InventoryModule

local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))

function InventoryModule.new(statSystem, setSystem)
    local self = setmetatable({}, InventoryModule)
    self.itemSystem = ItemSystem.new()
    self.statSystem = statSystem or StatUpgradeSystem
    self.setSystem = setSystem
    return self
end

function InventoryModule:AddItem(itemInfo)
    self.itemSystem:addItem(itemInfo)
end

function InventoryModule:EquipItem(slot, itemInfo)
    self.itemSystem:equip(slot, itemInfo)
end

function InventoryModule:RemoveItem(slot)
    return self.itemSystem:unequip(slot)
end

function InventoryModule:EquipFromInventory(index, slot)
    return self.itemSystem:equipFromInventory(index, slot)
end

function InventoryModule:UnequipToInventory(slot)
    return self.itemSystem:unequipToInventory(slot)
end

function InventoryModule:GetInventoryPage(page, perPage)
    return self.itemSystem:getInventoryPage(page, perPage)
end

function InventoryModule:GetInventoryPageCount(perPage)
    return self.itemSystem:getInventoryPageCount(perPage)
end

function InventoryModule:UpgradeItem(slot, amount, currencyType)
    return self.itemSystem:upgradeItem(slot, amount, currencyType)
end

function InventoryModule:UpgradeItemWithCrystals(slot, amount, currencyType)
    return self.itemSystem:upgradeItemWithFallback(slot, amount, currencyType)
end

-- Salvage functions are intentionally omitted on the client

function InventoryModule:TransferItem(index, target)
    if not target or not target.itemSystem then
        return false
    end
    return self.itemSystem:transferItem(index, target.itemSystem)
end

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
    if self.setSystem and self.setSystem.applyBonuses then
        combined = self.setSystem:applyBonuses(combined)
    end
    return combined
end

function InventoryModule:GetEquippedItems()
    if self.itemSystem and self.itemSystem.getEquippedItems then
        return self.itemSystem:getEquippedItems()
    end
    return {}
end

return InventoryModule
