-- SlotConstants.lua
-- Defines the list of valid equipment slots used by multiple modules

local SlotConstants = {}

---Ordered list of available equipment slots
SlotConstants.list = {"Hat", "Necklace", "Ring", "Armor", "Accessory", "Weapon"}

---Set for quick slot existence checks
SlotConstants.valid = {}
for _, name in ipairs(SlotConstants.list) do
    SlotConstants.valid[name] = true
end

return SlotConstants
