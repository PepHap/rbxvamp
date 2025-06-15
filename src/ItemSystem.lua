-- ItemSystem.lua
-- Manages equipment items and slots

local ItemSystem = {}
ItemSystem.__index = ItemSystem

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

-- Preloaded item templates describing available equipment. These definitions
-- are used when presenting random rewards to the player.
ItemSystem.templates = require("assets.items")
ItemSystem.upgradeCosts = require("assets.item_upgrade_costs")

-- Determine the highest level defined in the upgrade cost table. This value
-- acts as a hard cap for item upgrades.
do
    local max = 1
    for lvl in pairs(ItemSystem.upgradeCosts) do
        if lvl > max then
            max = lvl
        end
    end
    ItemSystem.maxLevel = max
end

local validSlots = {
    Hat = true,
    Necklace = true,
    Ring = true,
    Armor = true,
    Accessory = true,
    Weapon = true
}

---Creates a new item system instance with empty equipment slots.
-- @return table ItemSystem instance
function ItemSystem.new()
    return setmetatable({
        slots = {
            Hat = nil,
            Necklace = nil,
            Ring = nil,
            Armor = nil,
            Accessory = nil,
            Weapon = nil,
        },
        ---List of unequipped item tables stored in the inventory.
        inventory = {},
    }, ItemSystem)
end

local function assertValidSlot(slot)
    assert(validSlots[slot], ("Invalid slot: %s"):format(tostring(slot)))
end

function ItemSystem:equip(slot, item)
    assertValidSlot(slot)
    item.level = item.level or 1
    self.slots[slot] = item
end

---Adds an item table to the inventory list.
-- @param item table
function ItemSystem:addItem(item)
    table.insert(self.inventory, item)
end

---Removes an item from the inventory by index and returns it.
-- @param index number
-- @return table|nil
function ItemSystem:removeItem(index)
    local itm = table.remove(self.inventory, index)
    return itm
end

---Retrieves a slice of the inventory for the requested page.
-- @param page number page index starting at 1
-- @param perPage number items per page
-- @return table list of item entries
function ItemSystem:getInventoryPage(page, perPage)
    local startIdx = (page - 1) * perPage + 1
    local endIdx = math.min(startIdx + perPage - 1, #self.inventory)
    local result = {}
    for i = startIdx, endIdx do
        table.insert(result, self.inventory[i])
    end
    return result
end

---Returns how many pages of items exist for the given size.
-- @param perPage number items per page
-- @return number page count
function ItemSystem:getInventoryPageCount(perPage)
    if perPage <= 0 then
        return 1
    end
    return math.max(1, math.ceil(#self.inventory / perPage))
end

---Equips an item from the inventory list into the slot.
-- The removed item is no longer stored in the inventory.
-- @param index number inventory index
-- @param slot string slot to equip into
function ItemSystem:equipFromInventory(index, slot)
    local item = self:removeItem(index)
    if not item then
        return false
    end
    self:equip(slot, item)
    return true
end

---Unequips the item from the slot and stores it back into the inventory.
-- @param slot string equipment slot
-- @return table|nil removed item
function ItemSystem:unequipToInventory(slot)
    local itm = self:unequip(slot)
    if itm then
        table.insert(self.inventory, itm)
    end
    return itm
end

---Removes and returns the item currently in the slot.
-- @param slot string
-- @return any item that was removed
function ItemSystem:unequip(slot)
    assertValidSlot(slot)
    local removed = self.slots[slot]
    self.slots[slot] = nil
    return removed
end

---Upgrades the level of the item in the specified slot when enough currency
--  is provided. Costs for each level are defined in the ``upgradeCosts`` asset
--  table.
-- @param slot string equipment slot to upgrade
-- @param amount number number of levels to add
-- @param currencyType string currency key used for payment
-- @return boolean ``true`` if the upgrade succeeds
function ItemSystem:upgradeItem(slot, amount, currencyType)
    assertValidSlot(slot)
    local item = self.slots[slot]
    if not item or amount <= 0 then
        return false
    end
    local current = item.level or 1
    local target = current + amount
    if target > self.maxLevel then
        return false
    end
    local required = 0
    for lvl = current + 1, target do
        required = required + (self.upgradeCosts[lvl] or 0)
    end
    if not CurrencySystem:spend(currencyType, required) then
        return false
    end
    item.level = target
    return true
end

return ItemSystem
