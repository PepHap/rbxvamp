-- InventorySlots.lua
-- Creates equipment slot buttons and stores references for easy access

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local InventorySlots = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    slots = {},
    container = nil,
}

local SlotConstants = require(script.Parent:WaitForChild("SlotConstants"))
local slotNames = SlotConstants.list

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleUtil = require(script.Parent:WaitForChild("ModuleUtil"))
local slotIcons = ModuleUtil.loadAssetModule("slot_icons") or {}

-- Slots are arranged in three rows with two columns each using UIGridLayout
-- https://create.roblox.com/docs/reference/engine/classes/UIGridLayout
local COLUMN_COUNT = 2
local ROW_COUNT = 3
local CELL_SIZE = 80
local CELL_PADDING = 5

local function createInstance(className)
    if InventorySlots.useRobloxObjects and typeof ~= nil and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then
            inst.IgnoreGuiInset = true
        end
        return inst
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

---Creates slot buttons inside the given parent frame.
-- @param parent Frame|table container for the slots
-- @return table table of slot references indexed by slot name
function InventorySlots:create(parentFrame)
    if self.container then
        local ok, parentProp = pcall(function()
            return self.container.Parent
        end)
        if not ok or parentProp == nil then
            self.container = nil
            self.slots = {}
        else
            if parentFrame then
                parent(self.container, parentFrame)
            end
            return self.slots
        end
    end
    local frame = createInstance("Frame")
    frame.Name = "EquipmentSlots"
    if UDim2 and type(UDim2.new)=="function" then
        local totalWidth = COLUMN_COUNT * CELL_SIZE + (COLUMN_COUNT - 1) * CELL_PADDING
        local totalHeight = ROW_COUNT * CELL_SIZE + (ROW_COUNT - 1) * CELL_PADDING
        frame.Size = UDim2.new(0, totalWidth, 0, totalHeight)
    end
    parent(frame, parentFrame)
    self.container = frame

    local layout = createInstance("UIGridLayout")
    layout.Name = "Layout"
    if UDim2 and type(UDim2.new)=="function" then
        layout.CellSize = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
        if layout.CellPadding ~= nil then
            layout.CellPadding = UDim2.new(0, CELL_PADDING, 0, CELL_PADDING)
        end
        if Enum and Enum.FillDirection and Enum.SortOrder then
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            if layout.FillDirectionMaxCells ~= nil then
                layout.FillDirectionMaxCells = COLUMN_COUNT
            end
            if layout.StartCorner ~= nil then
                layout.StartCorner = Enum.StartCorner.TopLeft
            end
            if layout.HorizontalAlignment ~= nil then
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
            if layout.VerticalAlignment ~= nil then
                layout.VerticalAlignment = Enum.VerticalAlignment.Top
            end
        end
    end
    parent(layout, frame)

    local gridSupported = layout.FillDirectionMaxCells ~= nil

    for i, name in ipairs(slotNames) do
        local btn = createInstance("TextButton")
        btn.Name = name .. "Slot"
        if btn.LayoutOrder ~= nil then
            btn.LayoutOrder = i
        end
        if UDim2 and type(UDim2.new)=="function" then
            btn.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
            if not gridSupported then
                local row = math.floor((i-1) / COLUMN_COUNT)
                local col = (i-1) % COLUMN_COUNT
                local offsetX = col * (CELL_SIZE + CELL_PADDING)
                local offsetY = row * (CELL_SIZE + CELL_PADDING)
                btn.Position = UDim2.new(0, offsetX, 0, offsetY)
            end
        end
        btn.Text = ""
        parent(btn, frame)
        local icon = createInstance("ImageLabel")
        icon.Name = "Icon"
        if UDim2 and type(UDim2.new)=="function" then
            icon.Size = UDim2.new(1, 0, 1, 0)
        end
        icon.BackgroundTransparency = 1
        icon.Image = slotIcons[name] or ""
        parent(icon, btn)
        self.slots[name] = btn
    end

    return self.slots
end

return InventorySlots

