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

-- Adds child to parent for table and Instance representations
function GuiUtil.parent(child, parentObj)
    if not child or not parentObj then return end
    if typeof and typeof(child) == "Instance" then
        child.Parent = parentObj
    elseif type(child) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
        child.Parent = parentObj
    end
end

-- Returns the PlayerGui of the LocalPlayer when running in Roblox
function GuiUtil.getPlayerGui()
    if typeof and game and game.GetService then
        local players = game:GetService("Players")
        local lp = players.LocalPlayer
        if lp then
            return lp:FindFirstChildOfClass("PlayerGui") or lp:FindFirstChild("PlayerGui")
        end
    end
    return nil
end

-- Expands a GuiObject to cover the full screen
function GuiUtil.makeFullScreen(gui)
    if not gui or not UDim2 then return end
    if gui.Size ~= nil then
        gui.AnchorPoint = Vector2.new(0, 0)
        gui.Position = UDim2.new(0, 0, 0, 0)
        gui.Size = UDim2.new(1, 0, 1, 0)
    end
end

-- Keeps the GuiObject within the current screen bounds
function GuiUtil.clampToScreen(gui)
    if typeof and typeof(gui) == "Instance" and gui:IsA("GuiObject") then
        local camera = workspace.CurrentCamera
        if camera then
            local view = camera.ViewportSize
            local absSize = gui.AbsoluteSize
            local pos = gui.AbsolutePosition
            local x = math.clamp(pos.X, 0, view.X - absSize.X)
            local y = math.clamp(pos.Y, 0, view.Y - absSize.Y)
            gui.Position = UDim2.new(0, x, 0, y)
        end
    end
end

-- Toggles visibility for both Instance and table GUI representations
function GuiUtil.setVisible(obj, vis)
    vis = not not vis
    if typeof and typeof(obj) == "Instance" then
        if obj:IsA("GuiObject") then
            obj.Visible = vis
        elseif obj:IsA("LayerCollector") and obj.Enabled ~= nil then
            obj.Enabled = vis
        end
    elseif type(obj) == "table" then
        obj.visible = vis
    end
end

-- Applies aspect ratio and size constraints for responsive layouts
function GuiUtil.applyResponsive(frame, aspect, minW, minH, maxW, maxH)
    aspect = aspect or 1
    minW = minW or 0
    minH = minH or 0
    maxW = maxW or 10000
    maxH = maxH or 10000
    if typeof and typeof(frame) == "Instance" then
        local ar = Instance.new("UIAspectRatioConstraint")
        ar.AspectRatio = aspect
        ar.Parent = frame
        local sc = Instance.new("UISizeConstraint")
        sc.MinSize = Vector2.new(minW, minH)
        sc.MaxSize = Vector2.new(maxW, maxH)
        sc.Parent = frame
    elseif type(frame) == "table" then
        frame.aspectRatio = aspect
        frame.minSize = Vector2.new(minW, minH)
        frame.maxSize = Vector2.new(maxW, maxH)
    end
end

-- Adds decorative cross lines over the frame
function GuiUtil.addCrossDecor(frame)
    if not frame then return end
    if typeof and typeof(frame) == "Instance" then
        local h = Instance.new("Frame")
        h.Name = "DecorH"
        h.Size = UDim2.new(1, 0, 0, 1)
        h.Position = UDim2.new(0, 0, 0.5, 0)
        h.BackgroundColor3 = UITheme.Colors.BorderDark
        h.BorderSizePixel = 0
        h.Parent = frame
        local v = Instance.new("Frame")
        v.Name = "DecorV"
        v.Size = UDim2.new(0, 1, 1, 0)
        v.Position = UDim2.new(0.5, 0, 0, 0)
        v.BackgroundColor3 = UITheme.Colors.BorderDark
        v.BorderSizePixel = 0
        v.Parent = frame
    elseif type(frame) == "table" then
        frame.hasCrossDecor = true
    end
end

-- Connects a TextButton/ImageButton to a callback with simple hover effects
function GuiUtil.connectButton(btn, callback)
    if not btn then return end
    if typeof and typeof(btn) == "Instance" then
        if callback and btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(callback)
        end
        if btn.MouseEnter and btn.MouseLeave and btn.BackgroundColor3 then
            local normal = btn.BackgroundColor3
            local hover = normal:Lerp(Color3.new(1, 1, 1), 0.2)
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = hover
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = normal
            end)
        end
    elseif type(btn) == "table" then
        btn.hoverColor = Color3.new(1,1,1)
        btn.callback = callback
    end
end

-- Lowercase aliases for convenience
GuiUtil.createWindow = GuiUtil.CreateWindow
GuiUtil.createButton = GuiUtil.CreateButton
GuiUtil.createSlot = GuiUtil.CreateSlot
GuiUtil.createProgressBar = GuiUtil.CreateProgressBar
GuiUtil.createTextBox = GuiUtil.CreateTextBox
GuiUtil.createScrollingFrame = GuiUtil.CreateScrollingFrame
GuiUtil.createTabSystem = GuiUtil.CreateTabSystem
GuiUtil.createGrid = GuiUtil.CreateGrid
GuiUtil.animateWindowOpen = GuiUtil.AnimateWindowOpen
GuiUtil.animateWindowClose = GuiUtil.AnimateWindowClose
GuiUtil.createNotification = GuiUtil.CreateNotification
GuiUtil.centerElement = GuiUtil.CenterElement
GuiUtil.createDivider = GuiUtil.CreateDivider

return GuiUtil
