-- ItemSystem.lua
-- Manages equipment items and slots

local ItemSystem = {}
ItemSystem.__index = ItemSystem

-- Preloaded item templates describing available equipment. These definitions
-- are used when presenting random rewards to the player.
ItemSystem.templates = require("assets.items")
ItemSystem.upgradeCosts = require("assets.item_upgrade_costs")

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
        }
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
-- @param currency number available currency
-- @return boolean ``true`` if the upgrade succeeds
function ItemSystem:upgradeItem(slot, amount, currency)
    assertValidSlot(slot)
    local item = self.slots[slot]
    if not item then
        return false
    end
    local required = 0
    local current = item.level or 1
    for i = 1, amount do
        required = required + (self.upgradeCosts[current + i] or 0)
    end
    if currency < required then
        return false
    end
    item.level = current + amount
    return true
end

return ItemSystem
