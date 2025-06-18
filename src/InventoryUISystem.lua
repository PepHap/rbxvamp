-- InventoryUISystem.lua
-- Basic inventory GUI handling for equipment slots and stored items

local function detectRoblox()
    -- typeof and Instance only exist within Roblox
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local InventoryUI = {
    ---When true and running within Roblox, real Instance objects are used.
    useRobloxObjects = detectRoblox(),
    ---Reference to the created ScreenGui container
    gui = nil,
    ---Whether the inventory is currently visible
    visible = false,
    ---Child frame used for equipment slots
    equipmentFrame = nil,
    ---Child frame used for inventory items
    inventoryFrame = nil,
    ---Child frame used for showing stats
    statsFrame = nil,
    ---Current page index
    page = 1,
    ---Number of inventory items shown per page
    itemsPerPage = 30,
    ---Equipment slot awaiting an item selection
    selectedSlot = nil,
    ---Inventory index awaiting a slot selection
    pendingIndex = nil,
    ---Window frame containing all inventory UI elements
    window = nil,
    ---Optional blur effect applied when the window is visible
    blur = nil,
    ---Reference to the active ItemSystem instance provided by GameManager
    itemSystem = nil,
    ---Reference to the StatUpgradeSystem for base stats
    statSystem = nil,
    ---Reference to the SetBonusSystem for applying set bonuses
    setSystem = nil,
    ---References to equipment slot buttons
    slotRefs = nil,
}

-- Render order for equipment slots to ensure deterministic layout
local slotOrder = {"Hat", "Necklace", "Ring", "Armor", "Accessory", "Weapon"}

local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))

local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local InventorySlots = require(script.Parent:WaitForChild("InventorySlots"))
local InventoryGrid = require(script.Parent:WaitForChild("InventoryGrid"))

local function applyRarityColor(obj, rarity)
    if not obj or not Theme or not Theme.rarityColors then return end
    local col = Theme.rarityColors[rarity]
    if not col then return end
    local ok = pcall(function() obj.TextColor3 = col end)
    if not ok and type(obj) == "table" then
        obj.TextColor3 = col
    end
end

-- utility for environment agnostic Instance creation
local function createInstance(className)
    if InventoryUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "TextButton" then Theme.styleButton(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    if typeof and typeof(child) == "Instance" then
        if typeof(parentObj) == "Instance" then
            child.Parent = parentObj
        end
    else
        child.Parent = parentObj
    end
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

local function ensureGui(parent)
    if InventoryUI.gui then
        return InventoryUI.gui
    end
    if parent then
        InventoryUI.gui = parent
        return parent
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "InventoryUI"
    InventoryUI.gui = gui
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if InventoryUI.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

-- Clears any pending inventory or slot selection
local function clearSelection()
    InventoryUI.selectedSlot = nil
    InventoryUI.pendingIndex = nil
end

---Initializes the Inventory UI and binds page buttons.
-- @param items table ItemSystem instance
function InventoryUI:start(items, parentGui, statSystem, setSystem)
    self.itemSystem = items or self.itemSystem
    self.statSystem = statSystem or self.statSystem
    self.setSystem = setSystem or self.setSystem
    local gui = ensureGui(parentGui)

    -- no bundled images; create a plain window instead
    self.window = GuiUtil.createWindow("InventoryWindow")
    parent(self.window, gui)
    if UDim2 and type(UDim2.new)=="function" then
        self.window.Size = UDim2.new(1, 0, 1, 0)
        self.window.Position = UDim2.new(0, 0, 0, 0)
    end
    -- slightly visible background for readability
    if self.window.BackgroundTransparency ~= nil then
        local ok = pcall(function()
            self.window.BackgroundTransparency = 0.2
        end)
        if not ok and type(self.window) == "table" then
            self.window.BackgroundTransparency = 0.2
        end
    end

    if self.useRobloxObjects then
        local lighting = game:GetService("Lighting")
        if lighting and not self.blur then
            local ok, effect = pcall(function()
                return Instance.new("BlurEffect")
            end)
            if ok and effect then
                effect.Size = 0
                effect.Parent = lighting
                self.blur = effect
            end
        end
    end

    local prev = gui.FindFirstChild and gui:FindFirstChild("PrevPage") or createInstance("TextButton")
    prev.Name = "PrevPage"
    prev.Text = "<"
    if UDim2 and type(UDim2.new)=="function" then
        prev.Position = UDim2.new(0.45, -60, 1, -40)
    end
    parent(prev, gui)
    GuiUtil.connectButton(prev, function()
        InventoryUI:changePage(-1)
    end)
    if type(gui) == "table" then gui.PrevPage = prev end

    local nextBtn = gui.FindFirstChild and gui:FindFirstChild("NextPage") or createInstance("TextButton")
    nextBtn.Name = "NextPage"
    nextBtn.Text = ">"
    if UDim2 and type(UDim2.new)=="function" then
        nextBtn.Position = UDim2.new(0.55, 0, 1, -40)
    end
    parent(nextBtn, gui)
    GuiUtil.connectButton(nextBtn, function()
        InventoryUI:changePage(1)
    end)
    if type(gui) == "table" then gui.NextPage = nextBtn end

    self:update()
    self:setVisible(self.visible)
end

---Renders equipment slot buttons
local function renderSectionTitle(container, text)
    local lbl = createInstance("TextLabel")
    lbl.Name = "Title"
    lbl.Text = text
    if UDim2 and type(UDim2.new)=="function" then
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Position = UDim2.new(0, 0, 0, 0)
    end
    parent(lbl, container)
    return 25
end

local function renderEquipment(container, items)
    if not InventoryUI.slotRefs then
        clearChildren(container)
        renderSectionTitle(container, "Equipment")
        InventoryUI.slotRefs = InventorySlots:create(container)
    end
    for _, slot in ipairs(slotOrder) do
        local btn = InventoryUI.slotRefs[slot]
        if btn then
            local item = items.slots[slot]
            btn.Text = item and item.name or slot
            if item then
                applyRarityColor(btn, item.rarity)
            end
            if btn.SetAttribute then
                btn:SetAttribute("Slot", slot)
            elseif type(btn) == "table" then
                btn.Slot = slot
            end
            local connected = btn.GetAttribute and btn:GetAttribute("_connected")
            if not connected then
                GuiUtil.connectButton(btn, function()
                    InventoryUI:selectSlot(slot)
                end)
                if btn.SetAttribute then
                    btn:SetAttribute("_connected", true)
                end
            end
        end
    end
end

---Renders inventory item buttons for the current page
local function renderInventory(container, items, page, perPage)
    clearChildren(container)
    local offset = renderSectionTitle(container, "Inventory")
    local holder = createInstance("Frame")
    holder.Name = "GridHolder"
    if UDim2 and type(UDim2.new)=="function" then
        holder.Position = UDim2.new(0, 0, 0, offset)
        holder.Size = UDim2.new(1, 0, 1, -offset)
    end
    parent(holder, container)

    local grid = InventoryGrid.new()
    grid:create(holder, UDim2.new(0, 80, 0, 80))
    grid:ensureCells(perPage)

    local list = items:getInventoryPage(page, perPage)
    for i = 1, perPage do
        local idx = (page - 1) * perPage + i
        local item = list[i]
        grid:updateCell(i, item)
        local btn = grid.cells[i]
        if btn then
            applyRarityColor(btn, item and item.rarity)
            GuiUtil.connectButton(btn, function()
                InventoryUI:selectInventory(idx)
            end)
        end
    end
end

---Renders a list of basic stats derived from PlayerSystem and equipped items
local function renderStats(container, items, stats, setSys)
    clearChildren(container)
    local offset = renderSectionTitle(container, "Stats")
    local combined = {}
    if stats then
        for name, data in pairs(stats.stats) do
            combined[name] = (data.base or 0) * (data.level or 1)
        end
    end
    for _, itm in pairs(items.slots) do
        if itm and itm.stats then
            for k, v in pairs(itm.stats) do
                combined[k] = (combined[k] or 0) + v
            end
        end
    end
    if setSys and setSys.applyBonuses then
        combined = setSys:applyBonuses(combined)
    end
    local keys = {}
    for k in pairs(combined) do table.insert(keys, k) end
    table.sort(keys)
    local y = 0
    for _, name in ipairs(keys) do
        local lbl = createInstance("TextLabel")
        lbl.Text = string.format("%s: %s", name, tostring(combined[name]))
        if UDim2 and type(UDim2.new)=="function" then
            lbl.Position = UDim2.new(0, 0, 0, offset + y)
        end
        parent(lbl, container)
        y = y + 20
    end
end

---Updates the whole GUI based on the ItemSystem state
function InventoryUI:update()
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end
    local parentGui = self.window or gui
    local existing = parentGui.FindFirstChild and parentGui:FindFirstChild("Equipment")
    self.equipmentFrame = self.equipmentFrame or existing or createInstance("Frame")
    self.equipmentFrame.Name = "Equipment"
    if UDim2 and type(UDim2.new)=="function" then
        self.equipmentFrame.Position = UDim2.new(0, 0, 0, 0)
        self.equipmentFrame.Size = UDim2.new(0.25, 0, 1, 0)
    end
    existing = parentGui.FindFirstChild and parentGui:FindFirstChild("Inventory")
    self.inventoryFrame = self.inventoryFrame or existing or createInstance("Frame")
    self.inventoryFrame.Name = "Inventory"
    if UDim2 and type(UDim2.new)=="function" then
        self.inventoryFrame.Position = UDim2.new(0.25, 0, 0, 0)
        self.inventoryFrame.Size = UDim2.new(0.5, 0, 1, 0)
    end
    existing = parentGui.FindFirstChild and parentGui:FindFirstChild("Stats")
    self.statsFrame = self.statsFrame or existing or createInstance("Frame")
    self.statsFrame.Name = "Stats"
    if UDim2 and type(UDim2.new)=="function" then
        self.statsFrame.Position = UDim2.new(0.75, 0, 0, 0)
        self.statsFrame.Size = UDim2.new(0.25, 0, 1, 0)
    end

    clearChildren(self.equipmentFrame)
    clearChildren(self.inventoryFrame)
    clearChildren(self.statsFrame)

    parent(self.equipmentFrame, parentGui)
    parent(self.inventoryFrame, parentGui)
    parent(self.statsFrame, parentGui)

    local items = self.itemSystem
    if not items then
        return
    end

    renderEquipment(self.equipmentFrame, items)
    renderInventory(self.inventoryFrame, items, self.page, self.itemsPerPage)
    renderStats(self.statsFrame, items, self.statSystem, self.setSystem)
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

---Sets whether the inventory UI is visible.
-- @param on boolean
function InventoryUI:setVisible(on)
    self.visible = not not on
    if not self.visible then
        clearSelection()
    end
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
    if self.blur then
        local size = self.visible and 10 or 0
        local ok = pcall(function()
            self.blur.Size = size
        end)
        if not ok and type(self.blur) == "table" then
            self.blur.Size = size
        end
    end
end

---Toggles the visibility of the inventory UI.
function InventoryUI:toggle()
    if not self.gui then
        self:start(self.itemSystem)
    end
    self:setVisible(not self.visible)
end


return InventoryUI
