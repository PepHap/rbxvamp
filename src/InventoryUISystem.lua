-- InventoryUISystem.lua
-- Basic inventory GUI handling for equipment slots and stored items

local InventoryUI = {
    ---When true and running within Roblox, real Instance objects are used.
    useRobloxObjects = false,
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
    itemsPerPage = 20,
    ---Equipment slot awaiting an item selection
    selectedSlot = nil,
    ---Inventory index awaiting a slot selection
    pendingIndex = nil,
    ---Window frame containing all inventory UI elements
    window = nil,
    ---Reference to the active ItemSystem instance provided by GameManager
    itemSystem = nil,
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
        gui.Enabled = InventoryUI.visible
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
function InventoryUI:start(items, parentGui)
    self.itemSystem = items or self.itemSystem
    local gui = ensureGui(parentGui)

    -- no bundled images; create a plain window instead
    self.window = GuiUtil.createWindow("InventoryWindow")
    parent(self.window, gui)

    local prev = gui.FindFirstChild and gui:FindFirstChild("PrevPage") or createInstance("TextButton")
    prev.Name = "PrevPage"
    prev.Text = "<"
    if UDim2 and UDim2.new then
        prev.Position = UDim2.new(0, 10, 1, -40)
    end
    parent(prev, gui)
    GuiUtil.connectButton(prev, function()
        InventoryUI:changePage(-1)
    end)
    if type(gui) == "table" then gui.PrevPage = prev end

    local nextBtn = gui.FindFirstChild and gui:FindFirstChild("NextPage") or createInstance("TextButton")
    nextBtn.Name = "NextPage"
    nextBtn.Text = ">"
    if UDim2 and UDim2.new then
        nextBtn.Position = UDim2.new(0, 50, 1, -40)
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
local function renderEquipment(container, items)
    clearChildren(container)
    local index = 0
    for _, slot in ipairs(slotOrder) do
        local item = items.slots[slot]
        local btn = createInstance("TextButton")
        btn.Name = slot .. "Slot"
        btn.Text = item and item.name or "Empty"
        if item then
            applyRarityColor(btn, item.rarity)
        end
        if btn.SetAttribute then
            -- Store the slot identifier as an attribute instead of a direct
            -- property because Roblox Instances do not allow arbitrary fields.
            btn:SetAttribute("Slot", slot)
        elseif type(btn) == "table" then
            -- In unit tests we use plain tables as mock objects.
            btn.Slot = slot
        end
        if UDim2 and UDim2.new then
            btn.Position = UDim2.new(0, 0, 0, index * 25)
            btn.Size = UDim2.new(1, 0, 0, 24)
        end
        parent(btn, container)
        GuiUtil.connectButton(btn, function()
            InventoryUI:selectSlot(slot)
        end)
        index = index + 1
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
        applyRarityColor(btn, item.rarity)
        local idx = (page - 1) * perPage + i
        if btn.SetAttribute then
            btn:SetAttribute("Index", idx)
        elseif type(btn) == "table" then
            btn.Index = idx
        end
        if UDim2 and UDim2.new then
            btn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
            btn.Size = UDim2.new(1, 0, 0, 24)
        end
        parent(btn, container)
        GuiUtil.connectButton(btn, function()
            InventoryUI:selectInventory(idx)
        end)
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
    if UDim2 and UDim2.new then
        hLabel.Position = UDim2.new(0, 0, 0, 0)
    end
    parent(hLabel, container)
    local aLabel = createInstance("TextLabel")
    aLabel.Text = "Attack: " .. tostring(attack)
    if UDim2 and UDim2.new then
        aLabel.Position = UDim2.new(0, 0, 0, 20)
    end
    parent(aLabel, container)
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
    if UDim2 and UDim2.new then
        self.equipmentFrame.Position = UDim2.new(0, 10, 0.1, 0)
        self.equipmentFrame.Size = UDim2.new(0, 150, 0, 200)
    end
    existing = parentGui.FindFirstChild and parentGui:FindFirstChild("Inventory")
    self.inventoryFrame = self.inventoryFrame or existing or createInstance("Frame")
    self.inventoryFrame.Name = "Inventory"
    if UDim2 and UDim2.new then
        self.inventoryFrame.Position = UDim2.new(0, 170, 0.1, 0)
        self.inventoryFrame.Size = UDim2.new(0, 200, 0, 200)
    end
    existing = parentGui.FindFirstChild and parentGui:FindFirstChild("Stats")
    self.statsFrame = self.statsFrame or existing or createInstance("Frame")
    self.statsFrame.Name = "Stats"
    if UDim2 and UDim2.new then
        self.statsFrame.Position = UDim2.new(0, 380, 0.1, 0)
        self.statsFrame.Size = UDim2.new(0, 150, 0, 200)
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

---Sets whether the inventory UI is visible.
-- @param on boolean
function InventoryUI:setVisible(on)
    self.visible = not not on
    if not self.visible then
        clearSelection()
    end
    local gui = ensureGui()
    local parentGui = self.window or gui
    if parentGui.Enabled ~= nil then
        parentGui.Enabled = self.visible
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
