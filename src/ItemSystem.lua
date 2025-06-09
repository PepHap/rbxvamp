-- ItemSystem.lua
-- Manages equipment items and inventory slots

local ItemSystem = {}

ItemSystem.slots = {
    Hat = nil,
    Necklace = nil,
    Ring = nil,
    Armor = nil,
    Accessory = nil,
    Weapon = nil
}

function ItemSystem:equip(slot, item)
    -- TODO: validate and equip item
    self.slots[slot] = item
end

return ItemSystem
