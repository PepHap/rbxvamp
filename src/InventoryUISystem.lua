-- InventoryUISystem.lua
-- Basic inventory GUI handling for equipment slots and stored items

local InventoryUI = {
    ---When true and running within Roblox, real Instance objects are used.
    useRobloxObjects = false,
    ---Reference to the created ScreenGui container
    gui = nil,
    ---Child frame used for equipment slots
    equipmentFrame = nil,
    ---Child frame used for inventory items
    inventoryFrame = nil,
    ---Child frame used for showing stats
    statsFrame = nil,
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

-- Removes all child objects from the given container. When running in Roblox
-- this will destroy Instance children. In the test environment it resets the
-- `children` table used to emulate the hierarchy.
local function clearChildren(container)
    if typeof and typeof(container) == "Instance" and container.GetChildren then
        for _, child in ipairs(container:GetChildren()) do
            if child.Destroy then
                child:Destroy()
            end
        end
    elseif type(container) == "table" then
        container.children = {}
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

    local prev = gui:FindFirstChild("PrevPage") or createInstance("TextButton")
    prev.Name = "PrevPage"
    prev.Text = "<"
    parent(prev, gui)
    if prev.MouseButton1Click then
        prev.MouseButton1Click:Connect(function()
            InventoryUI:changePage(-1)
        end)
    else
        prev.onClick = function()
            InventoryUI:changePage(-1)
        end
    end
    if type(gui) == "table" then gui.PrevPage = prev end

    local nextBtn = gui:FindFirstChild("NextPage") or createInstance("TextButton")
    nextBtn.Name = "NextPage"
    nextBtn.Text = ">"
    parent(nextBtn, gui)
    if nextBtn.MouseButton1Click then
        nextBtn.MouseButton1Click:Connect(function()
            InventoryUI:changePage(1)
        end)
    else
        nextBtn.onClick = function()
            InventoryUI:changePage(1)
        end
    end
    if type(gui) == "table" then gui.NextPage = nextBtn end

    self:update()
end

---Renders equipment slot buttons
local function renderEquipment(container, items)
    clearChildren(container)
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
    clearChildren(container)
    local list = items:getInventoryPage(page, perPage)
    for i, item in ipairs(list) do
        local btn = createInstance("TextButton")
        btn.Name = "Inv" .. i
        btn.Text = item.name
        local idx = (page - 1) * perPage + i
        if btn.SetAttribute then
            btn:SetAttribute("Index", idx)
        elseif type(btn) == "table" then
            btn.Index = idx
        end
        parent(btn, container)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                InventoryUI:selectInventory(idx)
            end)
        else
            btn.onClick = function()
                InventoryUI:selectInventory(idx)
            end
        end
    end
end

---Renders a list of basic stats derived from PlayerSystem and equipped items
local function renderStats(container, items)
    clearChildren(container)
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
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end
    local existing = gui.FindFirstChild and gui:FindFirstChild("Equipment")
    self.equipmentFrame = self.equipmentFrame or existing or createInstance("Frame")
    self.equipmentFrame.Name = "Equipment"
    existing = gui.FindFirstChild and gui:FindFirstChild("Inventory")
    self.inventoryFrame = self.inventoryFrame or existing or createInstance("Frame")
    self.inventoryFrame.Name = "Inventory"
    existing = gui.FindFirstChild and gui:FindFirstChild("Stats")
    self.statsFrame = self.statsFrame or existing or createInstance("Frame")
    self.statsFrame.Name = "Stats"

    clearChildren(self.equipmentFrame)
    clearChildren(self.inventoryFrame)
    clearChildren(self.statsFrame)

    parent(self.equipmentFrame, gui)
    parent(self.inventoryFrame, gui)
    parent(self.statsFrame, gui)

    local items = self.itemSystem
    if not items then
        return
    end

    renderEquipment(self.equipmentFrame, items)
    renderInventory(self.inventoryFrame, items, self.page, self.itemsPerPage)
    renderStats(self.statsFrame, items)
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
