local WindowTabs = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
local GachaUI = require(script.Parent:WaitForChild("GachaUI"))

WindowTabs.inventoryButton = nil
WindowTabs.summonButton = nil
WindowTabs.labelsRoot = nil

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

local function findButtons(root)
    if not root then return end
    -- Prefer children of a frame named "Labels" if present
    local labels = root:FindFirstChild("Labels", true)
    if labels then
        WindowTabs.labelsRoot = labels
        for _, obj in ipairs(labels:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") then
                if not WindowTabs.inventoryButton and matches(obj, {"Inventory"}) then
                    WindowTabs.inventoryButton = obj
                elseif not WindowTabs.summonButton and matches(obj, {"Summon","Gacha"}) then
                    WindowTabs.summonButton = obj
                end
            end
        end
    end
    -- Fallback search across the entire gui
    if not WindowTabs.inventoryButton or not WindowTabs.summonButton then
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") then
                if not WindowTabs.inventoryButton and matches(obj, {"Inventory"}) then
                    WindowTabs.inventoryButton = obj
                elseif not WindowTabs.summonButton and matches(obj, {"Summon","Gacha"}) then
                    WindowTabs.summonButton = obj
                end
            end
        end
    end
end

local function style(btn, active)
    if not btn then return end
    if btn:IsA("GuiButton") then
        btn.AutoButtonColor = true
    end
    if active then
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 1
        if btn:IsA("ImageButton") then
            btn.ImageTransparency = 0
        end
    else
        btn.BackgroundTransparency = 0.5
        btn.BorderSizePixel = 0
        if btn:IsA("ImageButton") then
            btn.ImageTransparency = 0.5
        end
    end
end

function WindowTabs.update(active)
    style(WindowTabs.inventoryButton, active == "inventory")
    style(WindowTabs.summonButton, active == "summon")
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

function WindowTabs.init()
    UIBridge.waitForGui()
    local gui = UIBridge.getScreenGui()
    if not gui then return end
    findButtons(gui)
    local function connect(btn, handler)
        if not btn or btn._connected then return end
        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
            btn.MouseButton1Click:Connect(handler)
        else
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    handler()
                end
            end)
        end
        btn._connected = true
    end

    connect(WindowTabs.inventoryButton, WindowTabs.activateInventory)
    connect(WindowTabs.summonButton, WindowTabs.activateSummon)
    -- Default to inventory style when first initialized
    WindowTabs.update("inventory")
end

return WindowTabs
