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
}

local ItemSystem = require("src.ItemSystem")
local PlayerSystem = require("src.PlayerSystem")

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

---Renders equipment slot buttons
local function renderEquipment(container, items)
    container.children = {}
    for slot, item in pairs(items.slots) do
        local btn = createInstance("TextButton")
        btn.Name = slot .. "Slot"
        btn.Text = item and item.name or "Empty"
        btn.Slot = slot
        parent(btn, container)
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

    renderEquipment(gui.Equipment, ItemSystem)
    renderInventory(gui.Inventory, ItemSystem, self.page, self.itemsPerPage)
    renderStats(gui.Stats, ItemSystem)
end

---Changes the current inventory page and rerenders
-- @param delta number positive or negative page change
function InventoryUI:changePage(delta)
    local total = ItemSystem:getInventoryPageCount(self.itemsPerPage)
    self.page = math.max(1, math.min(total, self.page + delta))
    self:update()
end

return InventoryUI
