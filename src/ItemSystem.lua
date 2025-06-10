-- ItemSystem.lua
-- Manages equipment items and slots

local ItemSystem = {}
ItemSystem.__index = ItemSystem

local CurrencySystem = require("src.CurrencySystem")

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
