local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
    local self = setmetatable({}, Inventory)
    self.Slots = {
        Hat = nil,
        Necklace = nil,
        Ring = nil,
        Outfit = nil,
        Accessory = nil,
        Weapon = nil,
    }
    return self
end

function Inventory:Equip(slot, item)
    if self.Slots[slot] then
        -- return current item to the player if needed
    end
    self.Slots[slot] = item
end

function Inventory:Get(slot)
    return self.Slots[slot]
end

function Inventory:Upgrade(slot, cost, playerManager)
    local item = self.Slots[slot]
    if not item then
        return false
    end
    if not playerManager:SpendCurrency("UpgradeStones", cost) then
        return false
    end
    item.Level = (item.Level or 1) + 1
    return true
end

return Inventory
