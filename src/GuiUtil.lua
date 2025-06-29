-- GuiUtil.lua
-- Набор вспомогательных функций для создания и размещения объектов интерфейса

local GuiUtil = {}
local UITheme = require(script.Parent.UITheme)
local TweenService = game:GetService("TweenService")

-- Функция для создания основного фрейма окна
function GuiUtil.CreateWindow(parent, name, size, position)
    local window = Instance.new("Frame")
    window.Name = name
    window.Size = size or UITheme.Sizes.WindowMedium
    window.Position = position or UDim2.new(0.5, 0, 0.5, 0)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.ClipsDescendants = true
    window.Parent = parent

    UITheme.ApplyStyle(window, "Window")

    -- Добавляем скруглённые углы
    UITheme.CreateCorner(12).Parent = window

    -- Добавляем тень
    UITheme.CreateShadow(window, Vector2.new(4, 4), 8)

    -- Добавляем заголовочную панель
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = UITheme.Colors.BackgroundMedium
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window

    UITheme.CreateCorner(12).Parent = titleBar

    -- Маска для нижних углов заголовка
    local titleMask = Instance.new("Frame")
    titleMask.Size = UDim2.new(1, 0, 0, 12)
    titleMask.Position = UDim2.new(0, 0, 1, -12)
    titleMask.BackgroundColor3 = UITheme.Colors.BackgroundMedium
    titleMask.BorderSizePixel = 0
    titleMask.Parent = titleBar

    -- Заголовок
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = name
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    UITheme.ApplyStyle(titleLabel, "Title")

    -- Кнопка закрытия
    local closeButton = GuiUtil.CreateButton(titleBar, "✕", UDim2.new(0, 30, 0, 30))
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundColor3 = UITheme.Colors.Danger

    -- Область контента
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = window

    UITheme.CreatePadding(UITheme.Sizes.PaddingMedium).Parent = content

    return window, titleBar, content, closeButton
end

-- Функция для создания кнопки
function GuiUtil.CreateButton(parent, text, size, position)
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = size or UITheme.Sizes.ButtonMedium
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.Text = text or "Кнопка"
    button.Parent = parent

    UITheme.ApplyStyle(button, "Button")
    UITheme.CreateCorner(6).Parent = button

    -- Анимация при наведении
    local hoverTween = TweenService:Create(button, 
        TweenInfo.new(UITheme.Animations.FastTween), 
        UITheme.Styles.ButtonHover
    )

    local normalTween = TweenService:Create(button, 
        TweenInfo.new(UITheme.Animations.FastTween), 
        {BackgroundColor3 = UITheme.Colors.Primary}
    )

    button.MouseEnter:Connect(function()
        hoverTween:Play()
    end)

    button.MouseLeave:Connect(function()
        normalTween:Play()
    end)

    return button
end

-- Функция для создания слота предмета
function GuiUtil.CreateSlot(parent, size, position, rarity)
    local slot = Instance.new("Frame")
    slot.Name = "Slot"
    slot.Size = size or UITheme.Sizes.SlotMedium
    slot.Position = position or UDim2.new(0, 0, 0, 0)
    slot.Parent = parent

    UITheme.ApplyStyle(slot, "Slot")
    UITheme.CreateCorner(8).Parent = slot

    -- Обводка редкости
    if rarity then
        local stroke = UITheme.CreateStroke(UITheme.GetRarityColor(rarity), 2)
        stroke.Parent = slot
    end

    -- Иконка предмета
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Position = UDim2.new(0.1, 0, 0.1, 0)
    icon.BackgroundTransparency = 1
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slot

    -- Количество предметов
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "Count"
    countLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
    countLabel.Position = UDim2.new(0.6, 0, 0.7, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ""
    countLabel.TextScaled = true
    countLabel.Font = UITheme.Fonts.Bold
    countLabel.TextColor3 = UITheme.Colors.Warning
    countLabel.Parent = slot

    -- Кнопка для клика
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = slot

    return slot, icon, countLabel, button
end

-- Функция для создания прогресс-бара
function GuiUtil.CreateProgressBar(parent, size, position, currentValue, maxValue, color)
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressBar"
    progressFrame.Size = size or UDim2.new(1, 0, 0, 20)
    progressFrame.Position = position or UDim2.new(0, 0, 0, 0)
    progressFrame.Parent = parent

    UITheme.ApplyStyle(progressFrame, "ProgressBar")
    UITheme.CreateCorner(4).Parent = progressFrame

    local fillFrame = Instance.new("Frame")
    fillFrame.Name = "Fill"
    fillFrame.Size = UDim2.new(math.min(currentValue / maxValue, 1), 0, 1, 0)
    fillFrame.Position = UDim2.new(0, 0, 0, 0)
    fillFrame.BackgroundColor3 = color or UITheme.Colors.Primary
    fillFrame.BorderSizePixel = 0
    fillFrame.Parent = progressFrame

    UITheme.CreateCorner(4).Parent = fillFrame

    -- Текст прогресса
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = currentValue .. "/" .. maxValue
    progressText.TextColor3 = UITheme.Colors.TextPrimary
    progressText.TextScaled = true
    progressText.Font = UITheme.Fonts.SemiBold
    progressText.Parent = progressFrame

    return progressFrame, fillFrame, progressText
end

-- Функция для создания поля ввода
function GuiUtil.CreateTextBox(parent, placeholder, size, position)
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = size or UDim2.new(1, 0, 0, 40)
    textBox.Position = position or UDim2.new(0, 0, 0, 0)
    textBox.PlaceholderText = placeholder or "Введите текст..."
    textBox.Text = ""
    textBox.ClearTextOnFocus = false
    textBox.Parent = parent

    UITheme.ApplyStyle(textBox, "Input")
    UITheme.CreateCorner(6).Parent = textBox
    UITheme.CreatePadding(UDim.new(0, 10)).Parent = textBox

    return textBox
end

-- Функция для создания списка с прокруткой
function GuiUtil.CreateScrollingFrame(parent, size, position)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollingFrame"
    scrollFrame.Size = size or UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = position or UDim2.new(0, 0, 0, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = parent

    UITheme.ApplyStyle(scrollFrame, "ScrollFrame")
    UITheme.CreateCorner(8).Parent = scrollFrame

    -- Компоновка содержимого
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UITheme.Sizes.PaddingSmall
    listLayout.Parent = scrollFrame

    UITheme.CreatePadding(UITheme.Sizes.PaddingMedium).Parent = scrollFrame

    return scrollFrame, listLayout
end

-- Функция для создания вкладок
function GuiUtil.CreateTabSystem(parent, tabNames)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(1, 0, 0, 50)
    tabFrame.Position = UDim2.new(0, 0, 0, 0)
    tabFrame.BackgroundColor3 = UITheme.Colors.BackgroundMedium
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = parent

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = parent

    local tabs = {}
    local contents = {}
    local activeTab = nil

    for i, tabName in ipairs(tabNames) do
        -- Создаём кнопку вкладки
        local tabButton = GuiUtil.CreateButton(tabFrame, tabName, 
            UDim2.new(1/#tabNames, -5, 1, -10))
        tabButton.Position = UDim2.new((i-1)/#tabNames, 5, 0, 5)
        tabButton.BackgroundColor3 = UITheme.Colors.BackgroundLight

        -- Создаём содержимое вкладки
        local tabContent = Instance.new("Frame")
        tabContent.Name = tabName .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = i == 1
        tabContent.Parent = contentFrame

        UITheme.CreatePadding(UITheme.Sizes.PaddingMedium).Parent = tabContent

        tabs[tabName] = tabButton
        contents[tabName] = tabContent

        if i == 1 then
            activeTab = tabName
            tabButton.BackgroundColor3 = UITheme.Colors.Primary
        end

        -- Обработчик переключения вкладок
        tabButton.MouseButton1Click:Connect(function()
            if activeTab then
                tabs[activeTab].BackgroundColor3 = UITheme.Colors.BackgroundLight
                contents[activeTab].Visible = false
            end

            activeTab = tabName
            tabButton.BackgroundColor3 = UITheme.Colors.Primary
            tabContent.Visible = true
        end)
    end

    return tabFrame, contentFrame, tabs, contents
end

-- Функция для создания сетки предметов
function GuiUtil.CreateGrid(parent, columns, rows, slotSize, spacing)
    local gridFrame = Instance.new("Frame")
    gridFrame.Name = "Grid"
    gridFrame.Size = UDim2.new(1, 0, 1, 0)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = parent

    local slots = {}

    for row = 1, rows do
        slots[row] = {}
        for col = 1, columns do
            local slot = GuiUtil.CreateSlot(gridFrame, slotSize)
            slot.Position = UDim2.new(0, (col-1) * (slotSize.X.Offset + spacing), 
                                    0, (row-1) * (slotSize.Y.Offset + spacing))

            slots[row][col] = slot
        end
    end

    return gridFrame, slots
end

-- Функция для анимации появления окна
function GuiUtil.AnimateWindowOpen(window)
    window.Size = UDim2.new(0, 0, 0, 0)
    window.Visible = true

    local tween = TweenService:Create(window, 
        TweenInfo.new(UITheme.Animations.MediumTween, UITheme.Animations.EasingOut),
        {Size = window.Size or UITheme.Sizes.WindowMedium}
    )

    tween:Play()
    return tween
end

-- Функция для анимации закрытия окна
function GuiUtil.AnimateWindowClose(window, callback)
    local tween = TweenService:Create(window, 
        TweenInfo.new(UITheme.Animations.FastTween, UITheme.Animations.EasingIn),
        {Size = UDim2.new(0, 0, 0, 0)}
    )

    tween.Completed:Connect(function()
        window.Visible = false
        if callback then callback() end
    end)

    tween:Play()
    return tween
end

-- Функция для создания уведомления
function GuiUtil.CreateNotification(parent, text, duration, notificationType)
    duration = duration or 3
    notificationType = notificationType or "info"

    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = UITheme.Colors.BackgroundMedium
    notification.Parent = parent

    UITheme.CreateCorner(8).Parent = notification
    UITheme.CreateStroke(UITheme.Colors.Primary, 2).Parent = notification

    -- Цвет по типу уведомления
    local colors = {
        info = UITheme.Colors.Primary,
        success = UITheme.Colors.Success,
        warning = UITheme.Colors.Warning,
        error = UITheme.Colors.Danger,
    }

    local notifColor = colors[notificationType] or UITheme.Colors.Primary
    notification.BorderColor3 = notifColor

    -- Текст уведомления
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0, 10, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = UITheme.Colors.TextPrimary
    textLabel.TextWrapped = true
    textLabel.TextScaled = true
    textLabel.Font = UITheme.Fonts.Regular
    textLabel.Parent = notification

    -- Анимация появления
    notification.Position = UDim2.new(1, 0, 0, 20)
    local showTween = TweenService:Create(notification,
        TweenInfo.new(UITheme.Animations.MediumTween),
        {Position = UDim2.new(1, -320, 0, 20)}
    )
    showTween:Play()

    -- Автоматическое исчезновение
    game:GetService("Debris"):AddItem(notification, duration + 1)

    wait(duration)

    local hideTween = TweenService:Create(notification,
        TweenInfo.new(UITheme.Animations.MediumTween),
        {Position = UDim2.new(1, 0, 0, 20)}
    )
    hideTween:Play()

    return notification
end

-- Функция для центрирования элемента
function GuiUtil.CenterElement(element, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    element.AnchorPoint = Vector2.new(0.5, 0.5)
    element.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
end

-- Функция для создания разделителя
function GuiUtil.CreateDivider(parent, orientation)
    orientation = orientation or "horizontal"

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = UITheme.Colors.BorderDark
    divider.BorderSizePixel = 0
    divider.Parent = parent

    if orientation == "horizontal" then
        divider.Size = UDim2.new(1, 0, 0, 1)
    else
        divider.Size = UDim2.new(0, 1, 1, 0)
    end

    return divider
end

-- Parent ``child`` to ``parentObj`` for both real Instances and table mocks.
function GuiUtil.parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    if typeof and typeof(child) == "Instance" then
        local ok, err = pcall(function()
            child.Parent = parentObj
        end)
        if not ok then
            warn(err)
        end
    else
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
        child.Parent = parentObj
    end
end

-- Returns PlayerGui for the local player when running in Roblox.
function GuiUtil.getPlayerGui()
    if typeof then
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player then
            local ok, gui = pcall(player.WaitForChild, player, "PlayerGui")
            if ok then
                return gui
            end
        end
    end
    return nil
end

-- Expands a GUI object to cover the full screen area.
function GuiUtil.makeFullScreen(obj)
    if not obj then
        return
    end

    if UDim2 and type(UDim2.new) == "function" then
        if obj:IsA("GuiObject") then
            obj.Size = UDim2.new(1, 0, 1, 0)
            obj.Position = UDim2.new(0, 0, 0, 0)
        elseif obj:IsA("ScreenGui") then
            -- ScreenGuis do not have Size/Position properties
            if obj.IgnoreGuiInset ~= nil then
                obj.IgnoreGuiInset = true
            end
        end
    end
end

-- Ensures a frame stays within the screen bounds.
function GuiUtil.clampToScreen(frame)
    if not (frame and frame.Position and frame.Size and UDim2 and type(UDim2.new)=="function") then
        return
    end
    local pos = frame.Position
    local size = frame.Size
    local x = math.clamp(pos.X.Scale, 0, 1 - size.X.Scale)
    local y = math.clamp(pos.Y.Scale, 0, 1 - size.Y.Scale)
    frame.Position = UDim2.new(x, pos.X.Offset, y, pos.Y.Offset)
end

-- Simple responsive sizing based on screen width.
function GuiUtil.applyResponsive(frame, scale, minW, minH, maxW, maxH)
    if not (frame and UDim2 and type(UDim2.new)=="function") then return end
    local cam = workspace.CurrentCamera
    local vw, vh = 800, 600
    if cam and cam.ViewportSize then
        vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
    end
    local w = math.clamp(vw * (scale or 1), minW or 0, maxW or vw)
    local h = math.clamp(vh, minH or 0, maxH or vh)
    frame.Size = UDim2.new(0, w, 0, h)
end

-- Adds simple cross style decoration frames to ``parent``.
function GuiUtil.addCrossDecor(parent)
    if not (parent and Instance and type(Instance.new)=="function") then return end
    local vert = Instance.new("Frame")
    vert.Name = "CrossVert"
    vert.BackgroundColor3 = UITheme.Colors.BorderDark
    vert.BorderSizePixel = 0
    vert.Size = UDim2.new(0, 1, 1, 0)
    vert.Position = UDim2.new(0.5, 0, 0, 0)
    vert.Parent = parent

    local horiz = Instance.new("Frame")
    horiz.Name = "CrossHoriz"
    horiz.BackgroundColor3 = UITheme.Colors.BorderDark
    horiz.BorderSizePixel = 0
    horiz.Size = UDim2.new(1, 0, 0, 1)
    horiz.Position = UDim2.new(0, 0, 0.5, 0)
    horiz.Parent = parent
end

-- Connects ``callback`` to the button's activation event.
function GuiUtil.connectButton(btn, callback)
    if not (btn and callback) then return end

    local hover = UITheme.Styles.ButtonHover and UITheme.Styles.ButtonHover.BackgroundColor3
    if btn.SetAttribute then
        -- Instances cannot have arbitrary properties, so use attributes
        if btn:GetAttribute("hoverColor") == nil then
            btn:SetAttribute("hoverColor", hover)
        end
    else
        -- allow tables in tests to behave the same way
        btn.hoverColor = btn.hoverColor or hover
    end

    if btn.MouseButton1Click then
        btn.MouseButton1Click:Connect(callback)
    else
        btn.onClick = callback
    end
end

-- Highlights a TextButton when selected.
function GuiUtil.highlightButton(btn, on)
    if not btn then return end
    local hover = UITheme.Styles.ButtonHover and UITheme.Styles.ButtonHover.BackgroundColor3 or UITheme.Colors.Primary
    if on then
        if btn.BackgroundColor3 ~= nil then
            btn.BackgroundColor3 = hover
        end
    else
        if btn.BackgroundColor3 ~= nil then
            btn.BackgroundColor3 = UITheme.Colors.Primary
        end
    end
end

-- Applies the default label style from UITheme.
function GuiUtil.styleLabel(lbl)
    if not lbl then return end
    if UITheme and UITheme.styleLabel then
        UITheme.styleLabel(lbl)
    end
end

-- Sets the ``Visible`` state of a GUI object or table.
function GuiUtil.setVisible(obj, vis)
    if not obj then return end
    if obj.Visible ~= nil then
        obj.Visible = vis
    else
        obj.visible = vis
    end
end

-- Wrapper around ``CreateWindow`` with optional parent and close button.
function GuiUtil.createWindow(name, parent, showClose)
    parent = parent or GuiUtil.getPlayerGui()
    local window, titleBar, content, closeBtn = GuiUtil.CreateWindow(parent, name)
    GuiUtil.addCrossDecor(window)
    if showClose == false and closeBtn then
        closeBtn.Visible = false
    end
    return window, closeBtn
end

return GuiUtil
