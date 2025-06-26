-- HudSystem.lua
-- Отображает уровень игрока, валюту, здоровье, кнопки быстрого доступа и т.д.

local HudSystem = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent.UITheme)
local GuiUtil = require(script.Parent.GuiUtil)
local MenuIcons = require(script.Parent.Assets.menu_icons)
local BlurManager = require(script.Parent.BlurManager)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные HUD
local hudGui = nil
local healthBar = nil
local manaBar = nil
local staminaBar = nil
local experienceBar = nil
local currencyFrames = {}
local quickSlots = {}
local minimapFrame = nil

-- Данные игрока (обновляются через RemoteEvents)
local playerData = {
    level = 1,
    health = 100,
    maxHealth = 100,
    mana = 50,
    maxMana = 50,
    stamina = 80,
    maxStamina = 80,
    experience = 0,
    experienceToNext = 100,

    currencies = {
        gold = 0,
        crystals = 0,
        souls = 0,
        keys = 0
    },

    quickSlots = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [8] = nil,
        [9] = nil,
        [0] = nil
    }
}

-- Инициализация HUD
function HudSystem.Initialize()
    HudSystem.CreateHudGui()
    HudSystem.CreateHealthManaFrame()
    HudSystem.CreateExperienceBar()
    HudSystem.CreateCurrencyFrame()
    HudSystem.CreateQuickSlots()
    HudSystem.CreateMenuButtons()
    HudSystem.CreateMinimap()
    HudSystem.ConnectEvents()

    print("HudSystem инициализирован")
end

-- Создание основного GUI
function HudSystem.CreateHudGui()
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "GameHUD"
    hudGui.ResetOnSpawn = false
    hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hudGui.Parent = playerGui
end

-- Создание фрейма здоровья и маны
function HudSystem.CreateHealthManaFrame()
    local healthManaFrame = Instance.new("Frame")
    healthManaFrame.Name = "HealthManaFrame"
    healthManaFrame.Size = UDim2.new(0, 300, 0, 120)
    healthManaFrame.Position = UDim2.new(0, 20, 0, 20)
    healthManaFrame.BackgroundTransparency = 1
    healthManaFrame.Parent = hudGui

    -- Уровень игрока
    local levelFrame = Instance.new("Frame")
    levelFrame.Size = UDim2.new(0, 60, 0, 60)
    levelFrame.Position = UDim2.new(0, 0, 0, 0)
    levelFrame.BackgroundColor3 = UITheme.Colors.Primary
    levelFrame.BorderSizePixel = 0
    levelFrame.Parent = healthManaFrame

    UITheme.CreateCorner(30).Parent = levelFrame
    UITheme.CreateStroke(UITheme.Colors.Warning, 3).Parent = levelFrame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = tostring(playerData.level)
    levelLabel.TextColor3 = UITheme.Colors.TextPrimary
    levelLabel.TextScaled = true
    levelLabel.Font = UITheme.Fonts.Bold
    levelLabel.Parent = levelFrame

    -- Здоровье
    local healthFrame = Instance.new("Frame")
    healthFrame.Size = UDim2.new(0, 220, 0, 25)
    healthFrame.Position = UDim2.new(0, 70, 0, 5)
    healthFrame.BackgroundTransparency = 1
    healthFrame.Parent = healthManaFrame

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(0, 30, 1, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HP"
    healthLabel.TextColor3 = UITheme.Colors.Health
    healthLabel.Font = UITheme.Fonts.Bold
    healthLabel.TextSize = UITheme.Sizes.TextSmall
    healthLabel.Parent = healthFrame

    local healthBarFrame, healthBarFill, healthText = GuiUtil.CreateProgressBar(
        healthFrame, UDim2.new(0, 150, 1, 0), UDim2.new(0, 35, 0, 0),
        playerData.health, playerData.maxHealth, UITheme.Colors.Health
    )
    healthBar = {frame = healthBarFrame, fill = healthBarFill, text = healthText}

    -- Мана
    local manaFrame = Instance.new("Frame")
    manaFrame.Size = UDim2.new(0, 220, 0, 25)
    manaFrame.Position = UDim2.new(0, 70, 0, 35)
    manaFrame.BackgroundTransparency = 1
    manaFrame.Parent = healthManaFrame

    local manaLabel = Instance.new("TextLabel")
    manaLabel.Size = UDim2.new(0, 30, 1, 0)
    manaLabel.BackgroundTransparency = 1
    manaLabel.Text = "MP"
    manaLabel.TextColor3 = UITheme.Colors.Mana
    manaLabel.Font = UITheme.Fonts.Bold
    manaLabel.TextSize = UITheme.Sizes.TextSmall
    manaLabel.Parent = manaFrame

    local manaBarFrame, manaBarFill, manaText = GuiUtil.CreateProgressBar(
        manaFrame, UDim2.new(0, 150, 1, 0), UDim2.new(0, 35, 0, 0),
        playerData.mana, playerData.maxMana, UITheme.Colors.Mana
    )
    manaBar = {frame = manaBarFrame, fill = manaBarFill, text = manaText}

    -- Выносливость
    local staminaFrame = Instance.new("Frame")
    staminaFrame.Size = UDim2.new(0, 220, 0, 25)
    staminaFrame.Position = UDim2.new(0, 70, 0, 65)
    staminaFrame.BackgroundTransparency = 1
    staminaFrame.Parent = healthManaFrame

    local staminaLabel = Instance.new("TextLabel")
    staminaLabel.Size = UDim2.new(0, 30, 1, 0)
    staminaLabel.BackgroundTransparency = 1
    staminaLabel.Text = "ST"
    staminaLabel.TextColor3 = UITheme.Colors.Stamina
    staminaLabel.Font = UITheme.Fonts.Bold
    staminaLabel.TextSize = UITheme.Sizes.TextSmall
    staminaLabel.Parent = staminaFrame

    local staminaBarFrame, staminaBarFill, staminaText = GuiUtil.CreateProgressBar(
        staminaFrame, UDim2.new(0, 150, 1, 0), UDim2.new(0, 35, 0, 0),
        playerData.stamina, playerData.maxStamina, UITheme.Colors.Stamina
    )
    staminaBar = {frame = staminaBarFrame, fill = staminaBarFill, text = staminaText}
end

-- Создание полосы опыта
function HudSystem.CreateExperienceBar()
    local expFrame = Instance.new("Frame")
    expFrame.Name = "ExperienceFrame"
    expFrame.Size = UDim2.new(0, 400, 0, 30)
    expFrame.Position = UDim2.new(0.5, -200, 1, -50)
    expFrame.BackgroundTransparency = 1
    expFrame.Parent = hudGui

    local expLabel = Instance.new("TextLabel")
    expLabel.Size = UDim2.new(0, 40, 1, 0)
    expLabel.BackgroundTransparency = 1
    expLabel.Text = "EXP"
    expLabel.TextColor3 = UITheme.Colors.Experience
    expLabel.Font = UITheme.Fonts.Bold
    expLabel.TextSize = UITheme.Sizes.TextMedium
    expLabel.Parent = expFrame

    local expBarFrame, expBarFill, expText = GuiUtil.CreateProgressBar(
        expFrame, UDim2.new(0, 350, 1, 0), UDim2.new(0, 45, 0, 0),
        playerData.experience, playerData.experienceToNext, UITheme.Colors.Experience
    )
    experienceBar = {frame = expBarFrame, fill = expBarFill, text = expText}
end

-- Создание фрейма валют
function HudSystem.CreateCurrencyFrame()
    local currencyFrame = Instance.new("Frame")
    currencyFrame.Name = "CurrencyFrame"
    currencyFrame.Size = UDim2.new(0, 250, 0, 120)
    currencyFrame.Position = UDim2.new(1, -270, 0, 20)
    currencyFrame.BackgroundColor3 = UITheme.Colors.BackgroundDark
    currencyFrame.BackgroundTransparency = 0.2
    currencyFrame.BorderSizePixel = 0
    currencyFrame.Parent = hudGui

    UITheme.CreateCorner(10).Parent = currencyFrame
    UITheme.CreatePadding(UITheme.Sizes.PaddingMedium).Parent = currencyFrame

    local currencies = {
        {name = "gold", icon = MenuIcons.GetIcon("Interface", "gold"), color = UITheme.Colors.Gold},
        {name = "crystals", icon = MenuIcons.GetIcon("Interface", "gems"), color = UITheme.Colors.Crystals},
        {name = "souls", icon = MenuIcons.GetIcon("Interface", "souls"), color = UITheme.Colors.Souls},
        {name = "keys", icon = MenuIcons.GetIcon("Interface", "keys"), color = UITheme.Colors.Keys}
    }

    for i, currency in ipairs(currencies) do
        local currFrame = Instance.new("Frame")
        currFrame.Size = UDim2.new(1, 0, 0, 25)
        currFrame.Position = UDim2.new(0, 0, 0, (i-1) * 30)
        currFrame.BackgroundTransparency = 1
        currFrame.Parent = currencyFrame

        local currIcon = Instance.new("ImageLabel")
        currIcon.Size = UDim2.new(0, 20, 0, 20)
        currIcon.Position = UDim2.new(0, 0, 0, 2)
        currIcon.BackgroundTransparency = 1
        currIcon.Image = currency.icon
        currIcon.ImageColor3 = currency.color
        currIcon.Parent = currFrame

        local currLabel = Instance.new("TextLabel")
        currLabel.Size = UDim2.new(1, -25, 1, 0)
        currLabel.Position = UDim2.new(0, 25, 0, 0)
        currLabel.BackgroundTransparency = 1
        currLabel.Text = tostring(playerData.currencies[currency.name])
        currLabel.TextColor3 = UITheme.Colors.TextPrimary
        currLabel.TextXAlignment = Enum.TextXAlignment.Left
        currLabel.Font = UITheme.Fonts.SemiBold
        currLabel.TextSize = UITheme.Sizes.TextMedium
        currLabel.Parent = currFrame

        currencyFrames[currency.name] = currLabel
    end
end

-- Создание быстрых слотов
function HudSystem.CreateQuickSlots()
    local quickSlotFrame = Instance.new("Frame")
    quickSlotFrame.Name = "QuickSlotFrame"
    quickSlotFrame.Size = UDim2.new(0, 520, 0, 60)
    quickSlotFrame.Position = UDim2.new(0.5, -260, 1, -80)
    quickSlotFrame.BackgroundTransparency = 1
    quickSlotFrame.Parent = hudGui

    for i = 1, 10 do
        local slotKey = i == 10 and 0 or i
        local slot, icon, countLabel, button = GuiUtil.CreateSlot(
            quickSlotFrame, UDim2.new(0, 50, 0, 50), 
            UDim2.new(0, (i-1) * 52, 0, 5)
        )

        -- Номер слота
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0, 15, 0, 15)
        keyLabel.Position = UDim2.new(0, 2, 0, 2)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = tostring(slotKey)
        keyLabel.TextColor3 = UITheme.Colors.Warning
        keyLabel.TextScaled = true
        keyLabel.Font = UITheme.Fonts.Bold
        keyLabel.Parent = slot

        quickSlots[slotKey] = {
            slot = slot,
            icon = icon,
            count = countLabel,
            button = button,
            keyLabel = keyLabel
        }

        -- Обработчик клика
        button.MouseButton1Click:Connect(function()
            HudSystem.UseQuickSlot(slotKey)
        end)
    end
end

-- Создание кнопок меню
function HudSystem.CreateMenuButtons()
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "MenuFrame"
    menuFrame.Size = UDim2.new(0, 60, 0, 300)
    menuFrame.Position = UDim2.new(1, -80, 0.5, -150)
    menuFrame.BackgroundTransparency = 1
    menuFrame.Parent = hudGui

    local menuButtons = {
        {name = "inventory", icon = "inventory", key = "B"},
        {name = "character", icon = "character", key = "C"},
        {name = "skills", icon = "skills", key = "K"},
        {name = "quests", icon = "quests", key = "J"},
        {name = "map", icon = "map", key = "M"}
    }

    for i, buttonData in ipairs(menuButtons) do
        local button = GuiUtil.CreateButton(menuFrame, "", UDim2.new(0, 50, 0, 50))
        button.Position = UDim2.new(0, 0, 0, (i-1) * 55)
        button.Text = ""

        local buttonIcon = Instance.new("ImageLabel")
        buttonIcon.Size = UDim2.new(0, 30, 0, 30)
        buttonIcon.Position = UDim2.new(0.5, -15, 0.5, -15)
        buttonIcon.BackgroundTransparency = 1
        buttonIcon.Image = MenuIcons.GetIcon("Interface", buttonData.icon)
        buttonIcon.ImageColor3 = UITheme.Colors.TextPrimary
        buttonIcon.Parent = button

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0, 15, 0, 15)
        keyLabel.Position = UDim2.new(0, 2, 0, 2)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = buttonData.key
        keyLabel.TextColor3 = UITheme.Colors.Warning
        keyLabel.TextScaled = true
        keyLabel.Font = UITheme.Fonts.Bold
        keyLabel.Parent = button

        button.MouseButton1Click:Connect(function()
            HudSystem.OpenMenu(buttonData.name)
        end)
    end
end

-- Создание миникарты
function HudSystem.CreateMinimap()
    minimapFrame = Instance.new("Frame")
    minimapFrame.Name = "MinimapFrame"
    minimapFrame.Size = UDim2.new(0, 200, 0, 200)
    minimapFrame.Position = UDim2.new(1, -220, 0, 150)
    minimapFrame.BackgroundColor3 = UITheme.Colors.BackgroundDark
    minimapFrame.BackgroundTransparency = 0.2
    minimapFrame.BorderSizePixel = 0
    minimapFrame.Parent = hudGui

    UITheme.CreateCorner(15).Parent = minimapFrame
    UITheme.CreateStroke(UITheme.Colors.BorderDark, 2).Parent = minimapFrame

    local minimapLabel = Instance.new("TextLabel")
    minimapLabel.Size = UDim2.new(1, 0, 0, 30)
    minimapLabel.BackgroundTransparency = 1
    minimapLabel.Text = "Миникарта"
    minimapLabel.TextColor3 = UITheme.Colors.TextPrimary
    minimapLabel.Font = UITheme.Fonts.Bold
    minimapLabel.TextSize = UITheme.Sizes.TextMedium
    minimapLabel.Parent = minimapFrame

    -- Здесь можно добавить ViewportFrame для отображения карты
end

-- Подключение событий
function HudSystem.ConnectEvents()
    -- Обработка клавиш быстрого доступа
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyCode = input.KeyCode

            -- Быстрые слоты 1-9 и 0
            local slotKeys = {
                [Enum.KeyCode.One] = 1,
                [Enum.KeyCode.Two] = 2,
                [Enum.KeyCode.Three] = 3,
                [Enum.KeyCode.Four] = 4,
                [Enum.KeyCode.Five] = 5,
                [Enum.KeyCode.Six] = 6,
                [Enum.KeyCode.Seven] = 7,
                [Enum.KeyCode.Eight] = 8,
                [Enum.KeyCode.Nine] = 9,
                [Enum.KeyCode.Zero] = 0,
            }

            local slot = slotKeys[keyCode]
            if slot then
                HudSystem.UseQuickSlot(slot)
            end
        end
    end)
end

-- Обновление данных игрока
function HudSystem.UpdatePlayerData(newData)
    for key, value in pairs(newData) do
        if playerData[key] ~= nil then
            playerData[key] = value
        end
    end

    HudSystem.RefreshDisplay()
end

-- Обновление отображения
function HudSystem.RefreshDisplay()
    -- Обновление полос здоровья, маны, выносливости
    if healthBar then
        local healthPercent = playerData.health / playerData.maxHealth
        healthBar.fill.Size = UDim2.new(healthPercent, 0, 1, 0)
        healthBar.text.Text = playerData.health .. "/" .. playerData.maxHealth
    end

    if manaBar then
        local manaPercent = playerData.mana / playerData.maxMana
        manaBar.fill.Size = UDim2.new(manaPercent, 0, 1, 0)
        manaBar.text.Text = playerData.mana .. "/" .. playerData.maxMana
    end

    if staminaBar then
        local staminaPercent = playerData.stamina / playerData.maxStamina
        staminaBar.fill.Size = UDim2.new(staminaPercent, 0, 1, 0)
        staminaBar.text.Text = playerData.stamina .. "/" .. playerData.maxStamina
    end

    if experienceBar then
        local expPercent = playerData.experience / playerData.experienceToNext
        experienceBar.fill.Size = UDim2.new(expPercent, 0, 1, 0)
        experienceBar.text.Text = playerData.experience .. "/" .. playerData.experienceToNext
    end

    -- Обновление валют
    for currency, frame in pairs(currencyFrames) do
        if playerData.currencies[currency] then
            frame.Text = tostring(playerData.currencies[currency])
        end
    end
end

-- Использование быстрого слота
function HudSystem.UseQuickSlot(slotNumber)
    local slotData = playerData.quickSlots[slotNumber]
    if slotData then
        -- Здесь вызывается использование предмета
        print("Использование слота " .. slotNumber .. ": " .. (slotData.name or "пустой"))

        -- Анимация использования
        local slot = quickSlots[slotNumber].slot
        local tween = TweenService:Create(slot,
            TweenInfo.new(0.1, Enum.EasingStyle.Quart),
            {Size = UDim2.new(0, 45, 0, 45)}
        )
        tween:Play()

        tween.Completed:Connect(function()
            local backTween = TweenService:Create(slot,
                TweenInfo.new(0.1, Enum.EasingStyle.Quart),
                {Size = UDim2.new(0, 50, 0, 50)}
            )
            backTween:Play()
        end)
    end
end

-- Открытие меню
function HudSystem.OpenMenu(menuName)
    print("Открытие меню: " .. menuName)
    BlurManager.EnableBlur()

    -- Здесь вызывается соответствующая система UI
    local MenuUISystem = require(script.Parent.MenuUISystem)
    MenuUISystem.OpenMenu(menuName)
end

-- Обновление быстрого слота
function HudSystem.UpdateQuickSlot(slotNumber, itemData)
    playerData.quickSlots[slotNumber] = itemData

    local slot = quickSlots[slotNumber]
    if slot then
        if itemData then
            slot.icon.Image = itemData.icon or ""
            slot.count.Text = itemData.count > 1 and tostring(itemData.count) or ""
            slot.count.Visible = itemData.count > 1
        else
            slot.icon.Image = ""
            slot.count.Text = ""
            slot.count.Visible = false
        end
    end
end

-- Показать/скрыть HUD
function HudSystem.SetVisible(visible)
    if hudGui then
        hudGui.Enabled = visible
    end
end

-- Очистка ресурсов
function HudSystem.Cleanup()
    if hudGui then
        hudGui:Destroy()
        hudGui = nil
    end

    healthBar = nil
    manaBar = nil
    staminaBar = nil
    experienceBar = nil
    currencyFrames = {}
    quickSlots = {}
    minimapFrame = nil
end

return HudSystem
