-- @return table
function ItemSystem.new()
    return setmetatable({
        slots = {
            Hat = nil,
            Necklace = nil,
            Ring = nil,
            Armor = nil,
            Accessory = nil,
            Weapon = nil
        }
    }, ItemSystem)
end

local function assertValidSlot(self, slot)
    assert(self.slots[slot] ~= nil, ("Invalid slot: %s"):format(tostring(slot)))
end

function ItemSystem:equip(slot, item)
    assertValidSlot(self, slot)
    self.slots[slot] = item
end

---Removes and returns the item currently in the slot.
-- @param slot string
-- @return any item that was removed
function ItemSystem:unequip(slot)
    assertValidSlot(self, slot)
    local removed = self.slots[slot]
    self.slots[slot] = nil
    return removed
end

return ItemSystem
