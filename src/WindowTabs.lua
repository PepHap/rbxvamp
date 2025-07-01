local WindowTabs = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
local GachaUI = require(script.Parent:WaitForChild("GachaUI"))

WindowTabs.inventoryButton = nil
WindowTabs.summonButton = nil
WindowTabs.labelsRoot = nil
WindowTabs.allButtons = {}

local function matches(obj, variants)
    local name = string.lower(obj.Name)
    local text = ""
    if obj:IsA("TextButton") then
        text = string.lower(obj.Text)
    else
        local label = obj:FindFirstChildWhichIsA("TextLabel")
        if label then
            text = string.lower(label.Text)
        end
    end
    for _, v in ipairs(variants) do
        v = string.lower(v)
        if name == v or text:find(v) then
            return true
        end
    end
    return false
end

local function grabByName(root, name)
    local obj = root:FindFirstChild(name, true)
    if obj then
        return obj
    end
    for _, child in ipairs(root:GetDescendants()) do
        if string.lower(child.Name) == string.lower(name) then
            return child
        end
    end
    return nil
end

local function addButton(btn)
    if not btn then
        return
    end
    for _, existing in ipairs(WindowTabs.allButtons) do
        if existing == btn then
            return
        end
    end
    table.insert(WindowTabs.allButtons, btn)
end

local function findButtons(root)
    if not root then
        return end
    -- Prefer children of a frame named "Labels" if present
    local labels = root:FindFirstChild("Labels", true)
    if labels then
        WindowTabs.labelsRoot = labels
        for _, child in ipairs(labels:GetChildren()) do
            if child:IsA("GuiBase") then
                addButton(child)
            end
        end
    end

    WindowTabs.inventoryButton = WindowTabs.inventoryButton or grabByName(root, "InventoryButton")
    WindowTabs.summonButton = WindowTabs.summonButton or grabByName(root, "SummonButton")

    addButton(WindowTabs.inventoryButton)
    addButton(WindowTabs.summonButton)

    if not WindowTabs.inventoryButton or not WindowTabs.summonButton then
        local searchRoot = labels or root
        for _, obj in ipairs(searchRoot:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") then
                if not WindowTabs.inventoryButton and matches(obj, {"Inventory"}) then
                    WindowTabs.inventoryButton = obj
                    addButton(obj)
                elseif not WindowTabs.summonButton and matches(obj, {"Summon", "Gacha"}) then
                    WindowTabs.summonButton = obj
                    addButton(obj)
                end
            end
        end
    end
end

local function style(btn, active)
    if not btn then
        return
    end
    if btn:IsA("GuiButton") then
        btn.AutoButtonColor = true
    end

    -- Base transparency and border style toggle
    local bgTransparency = active and 0 or 0.6
    local borderSize = active and 1 or 0

    local function apply(obj)
        if obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
            obj.BackgroundTransparency = bgTransparency
            obj.BorderSizePixel = borderSize
            obj.ImageTransparency = active and 0 or 0.5
        elseif obj:IsA("Frame") then
            obj.BackgroundTransparency = bgTransparency
            obj.BorderSizePixel = borderSize
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.BackgroundTransparency = bgTransparency
            obj.BorderSizePixel = borderSize
            obj.TextTransparency = active and 0 or 0.5
        end
    end

    apply(btn)
    for _, child in ipairs(btn:GetDescendants()) do
        apply(child)
    end
end

function WindowTabs.update(active)
    for _, btn in ipairs(WindowTabs.allButtons) do
        if btn == WindowTabs.inventoryButton then
            style(btn, active == "inventory")
        elseif btn == WindowTabs.summonButton then
            style(btn, active == "summon")
        else
            style(btn, false)
        end
    end
end

function WindowTabs.activateInventory()
    InventoryUI.show()
    GachaUI.hide()
    WindowTabs.update("inventory")
end

function WindowTabs.activateSummon()
    GachaUI.show()
    InventoryUI.hide()
    WindowTabs.update("summon")
end

function WindowTabs.toggleInventory()
    InventoryUI.toggle()
    if InventoryUI.frame and InventoryUI.frame.Visible then
        GachaUI.hide()
        WindowTabs.update("inventory")
    else
        WindowTabs.update()
    end
end

function WindowTabs.toggleSummon()
    GachaUI.toggle()
    if GachaUI.frame and GachaUI.frame.Visible then
        InventoryUI.hide()
        WindowTabs.update("summon")
    else
        WindowTabs.update()
    end
end

function WindowTabs.init()
    UIBridge.waitForGui()
    local gui = UIBridge.getScreenGui()
    if not gui then return end
    findButtons(gui)
    local function connect(btn, handler)
        if not btn or btn:GetAttribute("_connected") then return end
        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
            btn.MouseButton1Click:Connect(handler)
        else
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    handler()
                end
            end)
        end
        btn:SetAttribute("_connected", true)
    end

    connect(WindowTabs.inventoryButton, WindowTabs.toggleInventory)
    connect(WindowTabs.summonButton, WindowTabs.toggleSummon)
    -- Default to inventory style when first initialized
    WindowTabs.update("inventory")
end

return WindowTabs
