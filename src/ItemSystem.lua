-- ItemSystem.lua
-- Manages equipment items and slots

local ItemSystem = {}
ItemSystem.__index = ItemSystem

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local SlotConstants = require(script.Parent:WaitForChild("SlotConstants"))
local LoggingSystem
do
    local RunService = game:GetService("RunService")
    if RunService and RunService.IsServer and RunService:IsServer() then
        LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))
    end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))

-- Preloaded item templates describing available equipment. These definitions
-- are used when presenting random rewards to the player.
ItemSystem.templates = ModuleUtil.loadAssetModule("items") or {}
ItemSystem.upgradeCosts = ModuleUtil.loadAssetModule("item_upgrade_costs") or {}
ItemSystem.rarityLimits = ModuleUtil.loadAssetModule("item_rarity_limit") or {}

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

local validSlots = SlotConstants.valid

---Maximum number of items that can be stored in the inventory.
ItemSystem.inventoryLimit = 100

-- Counter used to assign unique serial IDs to items.
ItemSystem.serialCounter = 0

---Generates a new unique serial ID.
-- @return number id value
function ItemSystem:generateId()
    self.serialCounter = (self.serialCounter or 0) + 1
    return self.serialCounter
end

---Ensures the provided item table has a serial ``id`` field.
-- @param item table item table
-- @return number assigned id
function ItemSystem:assignId(item)
    if not item then return nil end
    if not item.id then
        item.id = self:generateId()
    elseif item.id > (self.serialCounter or 0) then
        self.serialCounter = item.id
    end
    return item.id
end

---Returns a table of stats for the item taking the upgrade level into account.
-- Each level adds a 10% bonus to the base stats.
-- @param item table item entry with a ``stats`` field
-- @return table calculated stat values
function ItemSystem.getItemStats(item)
    if not item or type(item.stats) ~= "table" then
        return {}
    end
    local mult = 1
    local lvl = tonumber(item.level)
    if lvl and lvl > 1 then
        mult = 1 + 0.1 * (lvl - 1)
    end
    local result = {}
    for k, v in pairs(item.stats) do
        result[k] = v * mult
    end
    return result
end

---Creates a new item system instance with empty equipment slots.
-- @return table ItemSystem instance
function ItemSystem.new()
    local slotTbl = {}
    for _, name in ipairs(SlotConstants.list) do
        slotTbl[name] = nil
    end
    -- Instances inherit the default inventory limit so players can
    -- actually store items when unequipping or rolling gacha rewards.
    -- https://create.roblox.com/docs/reference/engine/classes/Instance
    return setmetatable({
        slots = slotTbl,
        ---List of unequipped item tables stored in the inventory.
        inventory = {},
        serialCounter = 0,
        inventoryLimit = ItemSystem.inventoryLimit,
    }, ItemSystem)
end

local function assertValidSlot(slot)
    assert(validSlots[slot], ("Invalid slot: %s"):format(tostring(slot)))
end

function ItemSystem:equip(slot, item)
    assertValidSlot(slot)
    assert(type(item) == "table", "item table expected")
    if item.slot and item.slot ~= slot then
        return false
    end
    item.level = item.level or 1
    self:assignId(item)
    self.slots[slot] = item
    if LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, item, "equip")
    end
    return true
end

---Adds an item table to the inventory list.
-- @param item table
function ItemSystem:addItem(item)
    if self:isInventoryFull() then
        return false
    end
    self:assignId(item)
    table.insert(self.inventory, item)
    if LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, item, "add")
    end
    return true
end

---Removes an item from the inventory by index and returns it.
-- @param index number
-- @return table|nil
function ItemSystem:removeItem(index)
    local itm = table.remove(self.inventory, index)
    if itm and LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, itm, "remove")
    end
    return itm
end

---Checks if the inventory reached the configured limit.
-- @return boolean true when no more items can be added
function ItemSystem:isInventoryFull()
    return #self.inventory >= (self.inventoryLimit or 0)
end

---Transfers an item to another ItemSystem instance.
-- @param index number inventory index to transfer
-- @param target table destination ItemSystem
-- @return boolean success
function ItemSystem:transferItem(index, target)
    if not target or not target.addItem then
        return false
    end
    local itm = self:removeItem(index)
    if not itm then
        return false
    end
    target:addItem(itm)
    return true
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
    local ok = self:equip(slot, item)
    if not ok then
        -- put the item back if it could not be equipped
        table.insert(self.inventory, index, item)
        return false
    end
    return true
end

---Unequips the item from the slot and stores it back into the inventory.
-- @param slot string equipment slot
-- @return table|nil removed item
function ItemSystem:unequipToInventory(slot)
    assertValidSlot(slot)
    self.inventory = self.inventory or {}
    if self:isInventoryFull() then
        return nil
    end
    local itm = self:unequip(slot)
    if not itm then
        return nil
    end
    -- Insert unequipped items at the start so they remain visible even when
    -- the inventory contains more entries than the display supports.
    table.insert(self.inventory, 1, itm)
    return itm
end

---Removes and returns the item currently in the slot.
-- @param slot string
-- @return any item that was removed
function ItemSystem:unequip(slot)
    assertValidSlot(slot)
    local removed = self.slots[slot]
    self.slots[slot] = nil
    if removed and LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, removed, "unequip")
    end
    return removed
end

---Returns a copy of the currently equipped items keyed by slot name.
-- @return table slot->item table
function ItemSystem:getEquippedItems()
    local result = {}
    for slot, itm in pairs(self.slots) do
        if itm then
            local copy = {}
            for k, v in pairs(itm) do
                copy[k] = v
            end
            result[slot] = copy
        end
    end
    return result
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
    local n = tonumber(amount)
    if not item or not n or n <= 0 then
        return false
    end
    local current = item.level or 1
    local target = current + n
    local rarity = item.rarity
    local limit = self.rarityLimits and self.rarityLimits[rarity] or self.maxLevel
    if target > limit or target > self.maxLevel then
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
    if LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, item, "upgrade")
    end
    return true
end

---Attempts to upgrade using the provided currency or crystals when lacking funds.
-- @param slot string equipment slot
-- @param amount number levels to add
-- @param currencyType string primary currency
-- @return boolean success
function ItemSystem:upgradeItemWithFallback(slot, amount, currencyType)
    currencyType = currencyType or "gold"
    assertValidSlot(slot)
    local item = self.slots[slot]
    local n = tonumber(amount)
    if not item or not n or n <= 0 then
        return false
    end
    local current = item.level or 1
    local rarity = item.rarity
    local limit = self.rarityLimits and self.rarityLimits[rarity] or self.maxLevel
    local target = math.min(current + n, self.maxLevel, limit)
    if target <= current then
        return false
    end
    local required = 0
    for lvl = current + 1, target do
        required = required + (self.upgradeCosts[lvl] or 0)
    end
    if not CurrencySystem:spend(currencyType, required) then
        local CrystalExchangeSystem = require(script.Parent:WaitForChild("CrystalExchangeSystem"))
        if not CrystalExchangeSystem:buyCurrency(currencyType, required) then
            return false
        end
        if not CurrencySystem:spend(currencyType, required) then
            return false
        end
    end
    item.level = target
    if LoggingSystem and LoggingSystem.logItem then
        LoggingSystem:logItem(nil, item, "upgrade")
    end
    return true
end

local function copy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local t = {}
    for k, v in pairs(tbl) do
        t[k] = copy(v)
    end
    return t
end

local function checksumString(str)
    local sum = 0
    for i = 1, #str do
        sum = (sum + string.byte(str, i)) % 2147483647
    end
    return sum
end

---Calculates a checksum over all item IDs and levels.
-- @return number checksum value
function ItemSystem:getChecksum()
    local entries = {}
    for slot, itm in pairs(self.slots) do
        if itm and itm.id then
            table.insert(entries, tostring(itm.id) .. ":" .. tostring(itm.level or 1))
        end
    end
    for _, itm in ipairs(self.inventory) do
        if itm.id then
            table.insert(entries, tostring(itm.id) .. ":" .. tostring(itm.level or 1))
        end
    end
    table.sort(entries)
    local str = table.concat(entries, "|")
    return checksumString(str)
end

---Returns serial id lists along with a checksum for client sync.
function ItemSystem:serializeForClient()
    local slots = {}
    for slot, itm in pairs(self.slots) do
        if itm and itm.id then
            slots[slot] = itm.id
        end
    end
    local inv = {}
    for i, itm in ipairs(self.inventory) do
        inv[i] = itm.id
    end
    return {slots = slots, inventory = inv, checksum = self:getChecksum()}
end

---Verifies that ``checksum`` matches the current inventory state.
-- @param checksum number checksum provided by the client
-- @return boolean
function ItemSystem:verifyChecksum(checksum)
    return checksum == self:getChecksum()
end

---Serializes the current state of equipped and stored items.
-- @return table data table
function ItemSystem:toData()
    return {
        slots = copy(self.slots),
        inventory = copy(self.inventory),
        serialCounter = self.serialCounter or 0,
    }
end

---Creates a new ItemSystem instance using saved data.
-- @param data table serialized state
-- @return table ItemSystem instance
function ItemSystem.fromData(data)
    local inst = ItemSystem.new()
    if type(data) ~= "table" then
        return inst
    end
    inst.serialCounter = tonumber(data.serialCounter) or 0
    for slot, itm in pairs(data.slots or {}) do
        if validSlots[slot] then
            local c = copy(itm)
            inst:assignId(c)
            inst.slots[slot] = c
        end
    end
    for _, itm in ipairs(data.inventory or {}) do
        local c = copy(itm)
        inst:assignId(c)
        table.insert(inst.inventory, c)
    end
    return inst
end

return ItemSystem
