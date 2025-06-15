-- InventoryUISystem.lua
-- Basic inventory GUI handling for equipment slots and stored items

local InventoryUI = {
    ---When true and running within Roblox, real Instance objects are used.
    useRobloxObjects = false,
    ---Reference to the created ScreenGui container
    gui = nil,
    ---Current page index
    page = 1,
    ---Number of inventory items shown per page
    itemsPerPage = 20,
    ---Equipment slot awaiting an item selection
    selectedSlot = nil,
    ---Inventory index awaiting a slot selection
    pendingIndex = nil,
    ---Reference to the active ItemSystem instance provided by GameManager
    itemSystem = nil,
}

local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))

local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))

-- utility for environment agnostic Instance creation
local function createInstance(className)
    if InventoryUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if InventoryUI.gui then
        return InventoryUI.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "InventoryUI"
    InventoryUI.gui = gui
    if InventoryUI.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

---Initializes the Inventory UI and binds page buttons.
-- @param items table ItemSystem instance
function InventoryUI:start(items)
    self.itemSystem = items or self.itemSystem
    local gui = ensureGui()
    gui.PrevPage = gui.PrevPage or createInstance("TextButton")
    gui.PrevPage.Text = "<"
    parent(gui.PrevPage, gui)
    if gui.PrevPage.MouseButton1Click then
        gui.PrevPage.MouseButton1Click:Connect(function()
            InventoryUI:changePage(-1)
        end)
    else
        gui.PrevPage.onClick = function()
            InventoryUI:changePage(-1)
        end
    end

    gui.NextPage = gui.NextPage or createInstance("TextButton")
    gui.NextPage.Text = ">"
    parent(gui.NextPage, gui)
    if gui.NextPage.MouseButton1Click then
        gui.NextPage.MouseButton1Click:Connect(function()
            InventoryUI:changePage(1)
        end)
    else
        gui.NextPage.onClick = function()
            InventoryUI:changePage(1)
        end
    end

    self:update()
end

---Renders equipment slot buttons
local function renderEquipment(container, items)
    container.children = {}
    for slot, item in pairs(items.slots) do
        local btn = createInstance("TextButton")
        btn.Name = slot .. "Slot"
        btn.Text = item and item.name or "Empty"
        btn.Slot = slot
        parent(btn, container)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                InventoryUI:selectSlot(slot)
            end)
        else
            btn.onClick = function()
                InventoryUI:selectSlot(slot)
            end
        end
    end
end

---Renders inventory item buttons for the current page
local function renderInventory(container, items, page, perPage)
    container.children = {}
    local list = items:getInventoryPage(page, perPage)
    for i, item in ipairs(list) do
        local btn = createInstance("TextButton")
        btn.Name = "Inv" .. i
        btn.Text = item.name
        btn.Index = (page - 1) * perPage + i
        parent(btn, container)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                InventoryUI:selectInventory(btn.Index)
            end)
        else
            btn.onClick = function()
                InventoryUI:selectInventory(btn.Index)
            end
        end
    end
end

---Renders a list of basic stats derived from PlayerSystem and equipped items
local function renderStats(container, items)
    container.children = {}
    local health = PlayerSystem.health
    local attack = 0
    for _, itm in pairs(items.slots) do
        if itm and itm.stats and itm.stats.attack then
            attack = attack + itm.stats.attack
        end
        if itm and itm.stats and itm.stats.health then
            health = health + itm.stats.health
        end
    end
    local hLabel = createInstance("TextLabel")
    hLabel.Text = "Health: " .. tostring(health)
    parent(hLabel, container)
    local aLabel = createInstance("TextLabel")
    aLabel.Text = "Attack: " .. tostring(attack)
    parent(aLabel, container)
end

---Updates the whole GUI based on the ItemSystem state
function InventoryUI:update()
    local gui = ensureGui()
    gui.children = gui.children or {}
    gui.Equipment = gui.Equipment or createInstance("Frame")
    gui.Inventory = gui.Inventory or createInstance("Frame")
    gui.Stats = gui.Stats or createInstance("Frame")
    parent(gui.Equipment, gui)
    parent(gui.Inventory, gui)
    parent(gui.Stats, gui)

    local items = self.itemSystem
    if not items then
        return
    end

    renderEquipment(gui.Equipment, items)
    renderInventory(gui.Inventory, items, self.page, self.itemsPerPage)
    renderStats(gui.Stats, items)
end

---Changes the current inventory page and rerenders
-- @param delta number positive or negative page change
function InventoryUI:changePage(delta)
    if not self.itemSystem then
        return
    end
    local total = self.itemSystem:getInventoryPageCount(self.itemsPerPage)
    self.page = math.max(1, math.min(total, self.page + delta))
    self:update()
end

---Handles clicking an inventory item. When a slot has been selected first,
--  the item will be equipped into that slot. Otherwise the index is stored
--  until a slot is chosen.
-- @param index number inventory index
function InventoryUI:selectInventory(index)
    if not self.itemSystem then
        return
    end
    if self.selectedSlot then
        self.itemSystem:equipFromInventory(index, self.selectedSlot)
        self.selectedSlot = nil
    else
        self.pendingIndex = index
    end
    self:update()
end

---Handles clicking an equipment slot. If an inventory index was selected
--  beforehand, the item is equipped here. Otherwise clicking an occupied
--  slot will unequip the item back into the inventory.
-- @param slot string equipment slot name
function InventoryUI:selectSlot(slot)
    if not self.itemSystem then
        return
    end
    if self.pendingIndex then
        self.itemSystem:equipFromInventory(self.pendingIndex, slot)
        self.pendingIndex = nil
        self.selectedSlot = nil
    else
        local itm = self.itemSystem.slots[slot]
        if itm then
            self.itemSystem:unequipToInventory(slot)
        else
            self.selectedSlot = slot
        end
    end
    self:update()
end


return InventoryUI
