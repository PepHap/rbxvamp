local GuiXmlLoader = {}

local function getEnumValue(enumObj, value)
    if typeof(enumObj) == "Enum" then
        local items = enumObj:GetEnumItems()
        return items[value + 1] or items[value]
    end
    return nil
end

local enumProps = {
    AutomaticSize = Enum.AutomaticSize,
    BorderMode = Enum.BorderMode,
    FillDirection = Enum.FillDirection,
    HorizontalAlignment = Enum.HorizontalAlignment,
    ResampleMode = Enum.ResamplerMode,
    ScaleType = Enum.ScaleType,
    SelectionBehaviorDown = Enum.SelectionBehavior,
    SelectionBehaviorLeft = Enum.SelectionBehavior,
    SelectionBehaviorRight = Enum.SelectionBehavior,
    SelectionBehaviorUp = Enum.SelectionBehavior,
    SizeConstraint = Enum.SizeConstraint,
    SortOrder = Enum.SortOrder,
    StartCorner = Enum.StartCorner,
    TextDirection = Enum.TextDirection,
    TextTruncate = Enum.TextTruncate,
    TextXAlignment = Enum.TextXAlignment,
    TextYAlignment = Enum.TextYAlignment,
    VerticalAlignment = Enum.VerticalAlignment,
}

local function mapStyleProperty(inst, value)
    local className = inst.ClassName
    local styleEnum
    local ok, enumObj = pcall(function()
        return Enum[className .. "Style"]
    end)
    if ok then
        styleEnum = enumObj
    elseif inst:IsA("GuiButton") then
        styleEnum = Enum.ButtonStyle
    end
    if styleEnum then
        return getEnumValue(styleEnum, value)
    end
    return nil
end

local function applyProperties(inst, props)
    for name, value in pairs(props) do
        local enumObj = enumProps[name]
        if enumObj and type(value) == "number" then
            local enumVal = getEnumValue(enumObj, value)
            if enumVal then
                value = enumVal
            end
        elseif name == "Style" and type(value) == "number" then
            local enumVal = mapStyleProperty(inst, value)
            if enumVal then
                value = enumVal
            end
        end
        local ok = pcall(function()
            inst[name] = value
        end)
        if not ok then
            -- ignore unknown or invalid props
        end
    end
end

function GuiXmlLoader.createFromTable(data, parent)
    local inst = Instance.new(data.ClassName)
    if data.Properties then
        applyProperties(inst, data.Properties)
    end
    if parent then
        inst.Parent = parent
    end
    if data.Children then
        for _, child in ipairs(data.Children) do
            GuiXmlLoader.createFromTable(child, inst)
        end
    end
    return inst
end

---Recursively searches for a descendant by name.
-- @param root Instance starting object
-- @param name string name of the child to locate
-- @return Instance? found object or nil
function GuiXmlLoader.findFirstDescendant(root, name)
    if not root or not name then
        return nil
    end
    if root.FindFirstChild then
        local child = root:FindFirstChild(name)
        if child then
            return child
        end
        for _, obj in ipairs(root:GetChildren()) do
            local found = GuiXmlLoader.findFirstDescendant(obj, name)
            if found then
                return found
            end
        end
    end
    return nil
end

return GuiXmlLoader
