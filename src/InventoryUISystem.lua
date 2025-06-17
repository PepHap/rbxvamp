
-- ========== окружение ==========
local function inRoblox()
    -- typeof и Instance существуют лишь в живом клиенте
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local Players = inRoblox() and game:GetService("Players") or nil
local LocalPlayer = Players and Players.LocalPlayer or nil

-------------------------------------------------------------------- класс
local InventoryUI = {}
InventoryUI.__index = InventoryUI

-------------------------------------------------------------------- util
local function getPlayerGui()
    if not inRoblox() then return nil end
    -- Гарантированно дождёмся появления PlayerGui
    return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 10) or nil
end

-------------------------------------------------------------------- ctor
function InventoryUI.new(itemSystem)
    local self = setmetatable({
        _gui          = nil,   -- ScreenGui
        _container    = nil,   -- Frame, куда кладём строки предметов
        _open         = false, -- текущее состояние окна
        itemSystem    = itemSystem,
    }, InventoryUI)

    -- Подпишемся на обновление инвентаря, если система его посылает
    if itemSystem and itemSystem.inventoryChanged then
        itemSystem.inventoryChanged:Connect(function(items)
            self:refresh(items)
        end)
    end

    return self
end

-------------------------------------------------------------------- private
function InventoryUI:_buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "InventoryUI"
    gui.Enabled         = false -- будет включаться/выключаться toggle’ом
    gui.IgnoreGuiInset  = true
    gui.ResetOnSpawn    = false
    gui.DisplayOrder    = 1000

    -- Корневой фрейм
    local frame = Instance.new("Frame")
    frame.Size                 = UDim2.fromScale(0.35, 0.55)
    frame.Position             = UDim2.fromScale(0.325, 0.225)
    frame.BackgroundColor3     = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency= 0.2
    frame.BorderSizePixel      = 0
    frame.Parent               = gui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Padding             = UDim.new(0, 4)
    layout.Parent              = frame

    self._gui       = gui
    self._container = frame
end

function InventoryUI:_ensureGui(parent)
    -- уже существует и имеет родителя
    if self._gui and (not inRoblox() or self._gui.Parent) then
        return self._gui
    end

    local targetParent = parent or getPlayerGui()

    if not self._gui then
        self:_buildGui()
    end

    if inRoblox() and targetParent then
        self._gui.Parent = targetParent
    end
    return self._gui
end

-------------------------------------------------------------------- public
function InventoryUI:toggle()
    self:_ensureGui()

    self._open        = not self._open
    self._gui.Enabled = self._open

    if self._open then
        self:refresh() -- ленивое обновление при каждом открытии
    end
end

function InventoryUI:refresh(newItems)
    self:_ensureGui()

    local items = newItems or (self.itemSystem and self.itemSystem:getItems()) or {}

    -- Сносим старые элементы
    for _, child in ipairs(self._container:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    -- Добавляем новые
    for i, item in ipairs(items) do
        local label = Instance.new("TextLabel")
        label.LayoutOrder        = i
        label.Size               = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text               = tostring(item.name or item)
        label.Font               = Enum.Font.Gotham
        label.TextSize           = 14
        label.TextColor3         = Color3.new(1, 1, 1)
        label.Parent             = self._container
    end
end

return InventoryUI
