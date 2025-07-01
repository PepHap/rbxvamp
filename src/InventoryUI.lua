local InventoryUI = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
-- ClientGameManager is only required during initialization to
-- avoid circular dependencies with GameManager.
local GameManager
local SlotConstants = require(script.Parent:WaitForChild("SlotConstants"))
local MessageUI = require(script.Parent:WaitForChild("MessageUI"))

InventoryUI.slots = {}
InventoryUI.inventoryCells = {}
InventoryUI.frame = nil

-- Waits until the ScreenGui created by UILoader becomes available.
-- https://create.roblox.com/docs/reference/engine/classes/ScreenGui


local function findSlots(root)
    if not root then return end
    local equip = root:FindFirstChild("EquipSlots", true)
    if equip then
        for _, name in ipairs(SlotConstants.list) do
            local btn = equip:FindFirstChild(name, true)
            if btn then
                if btn:IsA("GuiButton") then
                    btn.AutoButtonColor = true
                else
                    btn.Active = true
                end
                InventoryUI.slots[name] = btn
                -- https://create.roblox.com/docs/reference/engine/events/TextButton/MouseButton1Click
                btn.MouseButton1Click:Connect(function()
                    InventoryUI:unequip(name)
                end)
            end
        end
    end
    local invRoot = root:FindFirstChild("InventorySlots", true)
    if invRoot then
        local cells = {}
        for _, child in ipairs(invRoot:GetChildren()) do
            if child:IsA("ImageButton") and child.Name:match("InventorySlot") then
                table.insert(cells, child)
            end
        end
        table.sort(cells, function(a, b)
            local ai = tonumber(string.match(a.Name, '%d+')) or 0
            local bi = tonumber(string.match(b.Name, '%d+')) or 0
            return ai < bi
        end)
        for _, btn in ipairs(cells) do
            if btn:IsA("GuiButton") then
                btn.AutoButtonColor = true
            else
                btn.Active = true
            end
            table.insert(InventoryUI.inventoryCells, btn)
        end
        for i, btn in ipairs(InventoryUI.inventoryCells) do
            local idx = i
            btn.MouseButton1Click:Connect(function()
                InventoryUI:equipFromInventory(idx)
            end)
        end
    end
end

local function ensureLabel(btn)
    local label = btn:FindFirstChild("Label")
    if not label then
        label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Size = UDim2.fromScale(1,1)
        label.TextScaled = true
        label.Parent = btn
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.05,0)
        corner.Parent = label
    end
    return label
end

function InventoryUI:updateButton(btn, item)
    if not btn then return end
    local label = ensureLabel(btn)
    if item then
        label.Text = item.name or ""
        btn.BackgroundTransparency = 0.2
    else
        label.Text = ""
        btn.BackgroundTransparency = 0.8
    end
end

function InventoryUI:refresh()
    local itemSystem = GameManager.itemSystem
    if not itemSystem then return end
    for slot, btn in pairs(self.slots) do
        self:updateButton(btn, itemSystem.slots[slot])
    end
    for i, btn in ipairs(self.inventoryCells) do
        self:updateButton(btn, itemSystem.inventory[i])
    end
end

function InventoryUI:equipFromInventory(index)
    local inv = GameManager.inventory
    if not inv or not inv.EquipFromInventory then return end
    local item = inv.itemSystem.inventory[index]
    if not item then return end
    local ok = inv:EquipFromInventory(index, item.slot)
    if not ok then
        MessageUI.show("Не удалось экипировать")
        return
    end
    if item and item.name then
        MessageUI.show("Экипировано: " .. tostring(item.name))
    end
    self:refresh()
end

function InventoryUI:unequip(slot)
    local inv = GameManager.inventory
    if not (inv and inv.UnequipToInventory) then
        self:refresh()
        return
    end
    local removed = inv:UnequipToInventory(slot)
    if removed then
        if removed.name then
            MessageUI.show("Снято: " .. tostring(removed.name))
        else
            MessageUI.show("Снято")
        end
    else
        if inv.itemSystem and inv.itemSystem:isInventoryFull() then
            MessageUI.show("Инвентарь переполнен")
        else
            MessageUI.show("Пустой слот")
        end
    end
    self:refresh()
end

-- Hides the inventory window without altering other UI elements.
-- https://create.roblox.com/docs/reference/engine/classes/GuiObject#Visible
function InventoryUI.hide()
    if InventoryUI.frame then
        InventoryUI.frame.Visible = false
    end
end

function InventoryUI.show()
    UIBridge.waitForGui()
    local frame = InventoryUI.frame or UIBridge.waitForFrame("InventoryFrame")
    if not frame then return end
    InventoryUI.frame = frame
    if not next(InventoryUI.slots) then
        findSlots(frame)
    end
    frame.Visible = true
    InventoryUI:refresh()
end

function InventoryUI.toggle()
    -- Wait for the ScreenGui before searching for inventory frames
    UIBridge.waitForGui()
    local frame = InventoryUI.frame or UIBridge.waitForFrame("InventoryFrame")
    if not frame then return end
    InventoryUI.frame = frame
    if not next(InventoryUI.slots) then
        findSlots(frame)
    end
    frame.Visible = not frame.Visible
    if frame.Visible then
        InventoryUI:refresh()
    end
end

function InventoryUI.init()
    UIBridge.waitForGui()
    if not GameManager then
        GameManager = require(script.Parent:WaitForChild("ClientGameManager"))
    end
    InventoryUI.frame = UIBridge.waitForFrame("InventoryFrame")
    if InventoryUI.frame then
        InventoryUI.frame.Visible = false
        findSlots(InventoryUI.frame)
        InventoryUI:refresh()
    end
end

return InventoryUI
