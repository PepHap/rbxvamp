local InventoryGrid = {}
InventoryGrid.__index = InventoryGrid

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

InventoryGrid.useRobloxObjects = detectRoblox()

local function createInstance(className)
    if InventoryGrid.useRobloxObjects and Instance and type(Instance.new)=="function" then
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

function InventoryGrid.new()
    local self = setmetatable({}, InventoryGrid)
    self.cells = {}
    self.container = nil
    self.layout = nil
    self.columns = 5
    self.rows = 6
    return self
end

--
-- parentContainer: The parent UI object that will contain the grid
-- cellSize:      The desired size of each cell
function InventoryGrid:create(parentContainer, cellSize)
    local frame = createInstance("Frame")
    frame.Name = "InventoryGrid"
    if UDim2 and type(UDim2.new)=="function" then
        frame.Size = UDim2.new(1, 0, 1, 0)
    end
    -- avoid clobbering the parent() helper by using a different
    -- argument name for the container
    parent(frame, parentContainer)
    local layout = createInstance("UIGridLayout")
    layout.Name = "Layout"
    if UDim2 and type(UDim2.new)=="function" then
        layout.CellSize = cellSize or UDim2.new(0, 80, 0, 80)
        layout.CellPadding = UDim2.new(0, 5, 0, 5)
        if Enum and Enum.FillDirection and Enum.SortOrder then
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
        end
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
    local btn = createInstance("TextButton")
    btn.Name = "Cell" .. index
    if UDim2 and type(UDim2.new)=="function" then
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
    if item then
        local lvl = tonumber(item.level)
        if lvl and lvl > 1 then
            btn.Text = string.format("%s Lv%d", item.name, lvl)
        else
            btn.Text = item.name
        end
    else
        btn.Text = ""
    end
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
