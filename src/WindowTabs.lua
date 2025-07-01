local WindowTabs = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
local GachaUI = require(script.Parent:WaitForChild("GachaUI"))

WindowTabs.inventoryButton = nil
WindowTabs.summonButton = nil
WindowTabs.labelsRoot = nil
WindowTabs.allButtons = {}
WindowTabs.rootWindow = nil

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
        return
    end
    WindowTabs.rootWindow = root:FindFirstChild("Window")
        or root:FindFirstChild("window")
        or root
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
                if not WindowTabs.inventoryButton and matches(obj, {"Inventory", "Bag", "Backpack"}) then
                    WindowTabs.inventoryButton = obj
                    addButton(obj)
                elseif not WindowTabs.summonButton and matches(obj, {"Summon", "Gacha", "Summons"}) then
                    WindowTabs.summonButton = obj
                    addButton(obj)
                end
            end
        end
    end
end

local function style(btn)
    -- Leave all appearance settings untouched so the design exactly
    -- matches the original "gui.rbxmx" asset. Only ensure every tab
    -- element can receive input by enabling ``Active`` or the default
    -- button highlighting.
    if not btn then return end
    if btn:IsA("GuiButton") then
        btn.AutoButtonColor = true
    elseif btn:IsA("GuiObject") then
        btn.Active = true
    end
    for _, child in ipairs(btn:GetDescendants()) do
        if child:IsA("GuiButton") then
            child.AutoButtonColor = true
        elseif child:IsA("GuiObject") then
            child.Active = true
        end
    end
end

function WindowTabs.update(active)
    if WindowTabs.rootWindow then
        WindowTabs.rootWindow.Visible = active ~= nil
    end
    for _, btn in ipairs(WindowTabs.allButtons) do
        style(btn)
    end
end

function WindowTabs.activateInventory()
    InventoryUI.show()
    InventoryUI:refresh()
    GachaUI.hide()
    WindowTabs.update("inventory")
end

function WindowTabs.activateSummon()
    GachaUI.show()
    InventoryUI.hide()
    WindowTabs.update("summon")
end

function WindowTabs.toggleInventory()
    if InventoryUI.frame and InventoryUI.frame.Visible then
        InventoryUI.hide()
        WindowTabs.update()
    else
        WindowTabs.activateInventory()
    end
end

function WindowTabs.toggleSummon()
    if GachaUI.frame and GachaUI.frame.Visible then
        GachaUI.hide()
        WindowTabs.update()
    else
        WindowTabs.activateSummon()
    end
end

function WindowTabs.init()
    UIBridge.waitForGui()
    local gui = UIBridge.getScreenGui()
    if not gui then
        return
    end
    findButtons(gui)
    InventoryUI.hide()
    GachaUI.hide()
    local function connect(btn, handler)
        if not btn or btn:GetAttribute("_connected") then
            return
        end
        local function hook(obj)
            if obj:IsA("GuiButton") then
                obj.MouseButton1Click:Connect(handler)
            else
                if obj:IsA("GuiObject") then
                    obj.Active = true
                end
                obj.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        handler()
                    end
                end)
            end
        end
        hook(btn)
        for _, child in ipairs(btn:GetDescendants()) do
            if child:IsA("GuiButton") then
                hook(child)
            end
        end
        btn:SetAttribute("_connected", true)
    end

    connect(WindowTabs.inventoryButton, WindowTabs.activateInventory)
    connect(WindowTabs.summonButton, WindowTabs.activateSummon)
    -- Start with all windows hidden and no active tab
    WindowTabs.update()
end

return WindowTabs
