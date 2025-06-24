-- InventorySlots.lua
-- Creates equipment slot buttons and stores references for easy access

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local InventorySlots = {
    useRobloxObjects = detectRoblox(),
    slots = {},
    container = nil,
}

local SlotConstants = require(script.Parent:WaitForChild("SlotConstants"))
local slotNames = SlotConstants.list

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local slotIcons = require(assets:WaitForChild("slot_icons"))

local function createInstance(className)
    if InventorySlots.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
        frame.Size = UDim2.new(1, 0, 1, 0)
    end
    parent(frame, parentFrame)
    self.container = frame

    local layout = createInstance("UIGridLayout")
    layout.Name = "Layout"
    if UDim2 and type(UDim2.new)=="function" then
        layout.CellSize = UDim2.new(0, 80, 0, 80)
        if layout.CellPadding ~= nil then
            layout.CellPadding = UDim2.new(0, 2, 0, 2)
        end
        if Enum and Enum.FillDirection and Enum.SortOrder then
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            if layout.FillDirectionMaxCells ~= nil then
                layout.FillDirectionMaxCells = 2 -- two columns per row
            end
            if layout.StartCorner ~= nil then
                layout.StartCorner = Enum.StartCorner.TopLeft
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
            btn.Size = UDim2.new(0, 80, 0, 80)
            if not gridSupported then
                local row = math.floor((i-1) / 2)
                local col = (i-1) % 2
                btn.Position = UDim2.new(0, col * 82, 0, row * 82)
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

