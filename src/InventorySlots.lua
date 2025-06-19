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

local slotNames = {"Hat", "Necklace", "Ring", "Armor", "Accessory", "Weapon"}

local function createInstance(className)
    if InventorySlots.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
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

---Creates slot buttons inside the given parent frame.
-- @param parent Frame|table container for the slots
-- @return table table of slot references indexed by slot name
function InventorySlots:create(parentFrame)
    if self.container then
        if parentFrame then
            parent(self.container, parentFrame)
        end
        return self.slots
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
        if Enum and Enum.FillDirection and Enum.SortOrder then
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
        end
    end
    parent(layout, frame)

    for _, name in ipairs(slotNames) do
        local btn = createInstance("TextButton")
        btn.Name = name .. "Slot"
        if UDim2 and type(UDim2.new)=="function" then
            btn.Size = UDim2.new(0, 80, 0, 80)
        end
        parent(btn, frame)
        self.slots[name] = btn
    end

    return self.slots
end

return InventorySlots

