-- scripts/generate_gui.lua
-- Converts gui.rbxmx into a Lua module that builds the interface with
-- [`Instance.new`](https://create.roblox.com/docs/reference/engine/functions/Instance/new)
-- calls. This avoids loading the XML file directly at runtime.
-- The output is written to src/GeneratedGui.lua.

local function readFile(path)
    local f = assert(io.open(path, "r"))
    local data = f:read("*a")
    f:close()
    return data
end

local function parseAttributes(str)
    local attrs = {}
    for k, v in string.gmatch(str, "([%w_:%-]+)%s*=%s*\"(.-)\"") do
        attrs[k] = v
    end
    return attrs
end

local function parse(xml)
    local pos = 1
    local root = {children = {}}
    local stack = {root}
    while true do
        local s, e, closing, name, attrstr, empty = xml:find("<(/?)([%w_:%-]+)(.-)(/?)>", pos)
        if not s then break end
        local text = xml:sub(pos, s - 1)
        if text:match("%S") then
            local top = stack[#stack]
            top.children[#top.children + 1] = {text = text}
        end
        if closing == "/" then
            table.remove(stack)
        else
            local node = {name = name, attrs = parseAttributes(attrstr), children = {}}
            local parent = stack[#stack]
            parent.children[#parent.children + 1] = node
            if empty ~= "/" then
                stack[#stack + 1] = node
            end
        end
        pos = e + 1
    end
    return root.children[1]
end

local function propValue(node)
    local t = node.name
    local val = node.children[1] and node.children[1].text or ""
    if t == "string" or t == "BinaryString" then
        return string.format("%q", val)
    elseif t == "Content" then
        local urlNode = node.children[1]
        if urlNode and urlNode.name == "url" then
            val = urlNode.text or ""
        end
        return string.format("%q", val)
    elseif t == "bool" then
        return tostring(val == "true")
    elseif t == "int" or t == "int64" or t == "float" or t == "double" or t == "token" then
        return tonumber(val) or 0
    elseif t == "Vector2" then
        local x, y = 0, 0
        for _, c in ipairs(node.children) do
            if c.name == "X" then x = tonumber(c.children[1].text) end
            if c.name == "Y" then y = tonumber(c.children[1].text) end
        end
        return string.format("Vector2.new(%s,%s)", x, y)
    elseif t == "UDim2" then
        local xs, xo, ys, yo = 0, 0, 0, 0
        for _, c in ipairs(node.children) do
            if c.name == "XS" or c.name == "XScale" then xs = tonumber(c.children[1].text) end
            if c.name == "XO" or c.name == "XOffset" then xo = tonumber(c.children[1].text) end
            if c.name == "YS" or c.name == "YScale" then ys = tonumber(c.children[1].text) end
            if c.name == "YO" or c.name == "YOffset" then yo = tonumber(c.children[1].text) end
        end
        local baseW, baseH = 1920, 1080
        xs = xs + xo / baseW
        ys = ys + yo / baseH
        return string.format("UDim2.fromScale(%s,%s)", xs, ys)
    elseif t == "Color3" then
        local r, g, b = 0, 0, 0
        for _, c in ipairs(node.children) do
            if c.name == "R" then r = tonumber(c.children[1].text) end
            if c.name == "G" then g = tonumber(c.children[1].text) end
            if c.name == "B" then b = tonumber(c.children[1].text) end
        end
        return string.format("Color3.new(%s,%s,%s)", r, g, b)
    elseif t == "UDim" then
        local s, o = 0, 0
        for _, c in ipairs(node.children) do
            if c.name == "S" or c.name == "Scale" then s = tonumber(c.children[1].text) end
            if c.name == "O" or c.name == "Offset" then o = tonumber(c.children[1].text) end
        end
        local base = 1000
        s = s + o / base
        return string.format("UDim.new(%s,0)", s)
    elseif t == "Font" then
        local family = ""
        local weight = 400
        local style = "Normal"
        for _, c in ipairs(node.children) do
            if c.name == "Family" then
                local urlNode = c.children[1]
                family = urlNode and urlNode.text or ""
            elseif c.name == "Weight" then
                weight = tonumber(c.children[1] and c.children[1].text) or 400
            elseif c.name == "Style" then
                style = c.children[1] and c.children[1].text or "Normal"
            end
        end
        local weightEnum = "Enum.FontWeight.Regular"
        if weight and weight >= 700 then
            weightEnum = "Enum.FontWeight.Bold"
        end
        local styleEnum = "Enum.FontStyle." .. style
        return string.format("Font.new(%q, %s, %s)", family, weightEnum, styleEnum)
    end
    return string.format("%q", val)
end

local outLines = {}
local index = 0
local function genItem(node, parent)
    if node.name ~= "Item" then return end
    index = index + 1
    local var = "obj" .. index
    outLines[#outLines + 1] = string.format("    local %s = Instance.new(%q)", var, node.attrs.class)
    for _, child in ipairs(node.children) do
        if child.name == "Properties" then
            for _, p in ipairs(child.children) do
                if p.name then
                    local propName = p.attrs.name
                    if propName ~= "SourceAssetId"
                        and propName ~= "Tags"
                        and propName ~= "LocalizationMatchIdentifier"
                        and propName ~= "LocalizationMatchedSourceText" then
                        outLines[#outLines + 1] =
                            string.format("    %s.%s = %s", var, propName, propValue(p))
                    end
                end
            end
        elseif child.name == "Item" then
            genItem(child, var)
        end
    end
    if parent then
        outLines[#outLines + 1] = string.format("    %s.Parent = %s", var, parent)
    end
    if node.attrs.class == "TextLabel" then
        local cornerVar = "corner" .. index
        outLines[#outLines + 1] = string.format("    local %s = Instance.new(\"UICorner\")", cornerVar)
        outLines[#outLines + 1] = string.format("    %s.CornerRadius = UDim.new(0.05,0)", cornerVar)
        outLines[#outLines + 1] = string.format("    %s.Parent = %s", cornerVar, var)
    end
end

local xml = readFile("gui.rbxmx")
local tree = parse(xml)

outLines[#outLines + 1] = "local function createGui(parent)"
outLines[#outLines + 1] = "    local screenGui = Instance.new(\"ScreenGui\")"
outLines[#outLines + 1] = "    screenGui.Name = \"InventoryUI\""
outLines[#outLines + 1] = "    screenGui.IgnoreGuiInset = true"
outLines[#outLines + 1] = "    screenGui.ResetOnSpawn = false"
outLines[#outLines + 1] = "    if parent then screenGui.Parent = parent end"

for _, child in ipairs(tree.children) do
    if child.name == "Item" then
        genItem(child, "screenGui")
    end
end

outLines[#outLines + 1] = "    return screenGui"
outLines[#outLines + 1] = "end"
outLines[#outLines + 1] = "return createGui"

local outFile = assert(io.open("src/GeneratedGui.lua", "w"))
outFile:write(table.concat(outLines, "\n"))
outFile:close()

print("Generated src/GeneratedGui.lua")
