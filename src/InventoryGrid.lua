local InventoryGrid = {}
InventoryGrid.__index = InventoryGrid

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

InventoryGrid.useRobloxObjects = detectRoblox()

local function createInstance(className)
    if InventoryGrid.useRobloxObjects then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then return end
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

function InventoryGrid.new()
    local self = setmetatable({}, InventoryGrid)
    self.cells = {}
    self.container = nil
    self.layout = nil
    self.columns = 5
    self.rows = 6
    return self
end

function InventoryGrid:create(parent, cellSize)
    local frame = createInstance("Frame")
    frame.Name = "InventoryGrid"
    if UDim2 and UDim2.new then
        frame.Size = UDim2.new(1, 0, 1, 0)
    end
    parent(frame, parent)
    local layout = createInstance("UIGridLayout")
    layout.Name = "Layout"
    if UDim2 and UDim2.new then
        layout.CellSize = cellSize or UDim2.new(0, 80, 0, 80)
        layout.CellPadding = UDim2.new(0, 5, 0, 5)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    parent(layout, frame)
    self.container = frame
    self.layout = layout
    return frame
end

function InventoryGrid:ensureCells(count)
    for i = 1, count do
        if not self.cells[i] then
            self:addCell(i)
        end
    end
    for i = count + 1, #self.cells do
        self:removeCell(i)
    end
end

function InventoryGrid:clear()
    for i = #self.cells, 1, -1 do
        self:removeCell(i)
    end
end

function InventoryGrid:addCell(index, item)
    if not self.container then return nil end
    local btn = createInstance("ImageButton")
    btn.Name = "Cell" .. index
    if UDim2 and UDim2.new then
        btn.Size = self.layout and self.layout.CellSize or UDim2.new(0, 80, 0, 80)
    end
    parent(btn, self.container)
    self.cells[index] = btn
    self:updateCell(index, item)
    return btn
end

function InventoryGrid:updateCell(index, item)
    local btn = self.cells[index]
    if not btn then return end
    if btn.SetAttribute then
        btn:SetAttribute("Index", index)
    else
        btn.Index = index
    end
    btn.Text = item and item.name or ""
end

function InventoryGrid:removeCell(index)
    local btn = self.cells[index]
    if not btn then return end
    if btn.Destroy then
        btn:Destroy()
    else
        if btn.Parent then
            btn.Parent = nil
        end
    end
    self.cells[index] = nil
end

return InventoryGrid
