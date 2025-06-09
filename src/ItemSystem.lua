-- ItemSystem.lua
-- Manages equipment items and slots

local ItemSystem = {}

local validSlots = {
    Hat = true,
    Necklace = true,
    Ring = true,
    Armor = true,
    Accessory = true,
    Weapon = true
}

ItemSystem.slots = {
    Hat = nil,
    Necklace = nil,
    Ring = nil,
    Armor = nil,
    Accessory = nil,
    Weapon = nil
}

local function assertValidSlot(slot)
    assert(validSlots[slot], ("Invalid slot: %s"):format(tostring(slot)))
end

function ItemSystem:equip(slot, item)
    assertValidSlot(slot)
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

return ItemSystem
