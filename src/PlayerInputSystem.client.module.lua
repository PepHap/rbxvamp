-- PlayerInputSystem.client.module.lua
-- Управление вводом и назначением клавиш для открытия различных интерфейсов

local PlayerInputSystem = {}

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Назначенные клавиши для различных интерфейсов
local INPUT_KEYS = {
    inventoryKey = Enum.KeyCode.B,
    skillKey = Enum.KeyCode.K,
    companionKey = Enum.KeyCode.L,
    gachaKey = Enum.KeyCode.G,
    rewardKey = Enum.KeyCode.R,
    questKey = Enum.KeyCode.J,
    achievementKey = Enum.KeyCode.H,
    statsKey = Enum.KeyCode.U,
    progressKey = Enum.KeyCode.P,
    levelKey = Enum.KeyCode.V,
    lobbyKey = Enum.KeyCode.O,
    partyKey = Enum.KeyCode.Y,
    menuKey = Enum.KeyCode.M,
    adminKey = Enum.KeyCode.F10,

    -- Дополнительные клавиши
    -- Используем Return, так как "Enter" отсутствует в Enum.KeyCode
    -- Дополнительно обрабатываем KeypadEnter для совместимости
    chatKey = Enum.KeyCode.Return,
    screenshotKey = Enum.KeyCode.F12,
    fullscreenKey = Enum.KeyCode.F11,
    settingsKey = Enum.KeyCode.Escape,
    helpKey = Enum.KeyCode.F1,

    -- Быстрые слоты (1-9, 0)
    quickSlot1 = Enum.KeyCode.One,
    quickSlot2 = Enum.KeyCode.Two,
    quickSlot3 = Enum.KeyCode.Three,
    quickSlot4 = Enum.KeyCode.Four,
    quickSlot5 = Enum.KeyCode.Five,
    quickSlot6 = Enum.KeyCode.Six,
    quickSlot7 = Enum.KeyCode.Seven,
    quickSlot8 = Enum.KeyCode.Eight,
    quickSlot9 = Enum.KeyCode.Nine,
    quickSlot0 = Enum.KeyCode.Zero,

    -- Функциональные клавиши
    autoAttack = Enum.KeyCode.Space,
    interact = Enum.KeyCode.F,
    run = Enum.KeyCode.LeftShift,
    walk = Enum.KeyCode.LeftControl,
    jump = Enum.KeyCode.Space,

    -- Камера и интерфейс
    toggleUI = Enum.KeyCode.F2,
    toggleMinimap = Enum.KeyCode.F3,
    toggleNames = Enum.KeyCode.F4,
    toggleChat = Enum.KeyCode.F5,
}

-- Состояния интерфейсов
local interfaceStates = {
    inventory = false,
    skills = false,
    companion = false,
    gacha = false,
    reward = false,
    quest = false,
    achievement = false,
    stats = false,
    progress = false,
    level = false,
    lobby = false,
    party = false,
    menu = false,
    admin = false,
    settings = false,
    help = false,
}

-- Модули UI систем
local uiModules = {}

-- Инициализация системы ввода
function PlayerInputSystem.Initialize()
    PlayerInputSystem.LoadUIModules()
    PlayerInputSystem.ConnectInputEvents()
    PlayerInputSystem.SetupMobileControls()

    print("PlayerInputSystem инициализирован")
end

-- Provide a start method used by ClientGameRunner to initialize the
-- input system. This simply delegates to ``Initialize`` for backward
-- compatibility with older code.
function PlayerInputSystem:start()
    self.Initialize()
end

-- Загрузка модулей UI
function PlayerInputSystem.LoadUIModules()
    -- Загружаем все UI системы
    local uiSystemNames = {
        "InventoryUISystem",
        "SkillUISystem",
        "CompanionUISystem",
        "SkillTreeUISystem",
        "StatUpgradeUISystem",
        "QuestUISystem",
        "AchievementUISystem",
        "GachaUISystem",
        "RewardGaugeUISystem",
        "DungeonUISystem",
        "RaidUISystem",
        "LobbyUISystem",
        "PartyUISystem",
        "ProgressMapUISystem",
        "ScoreboardUISystem",
        "LevelUISystem",
        -- Legacy PlayerUISystem duplicated HUD elements and is disabled.
        "EnemyUISystem",
        "MenuUISystem"
    }

    for _, systemName in ipairs(uiSystemNames) do
        local success, module = pcall(function()
            return require(script.Parent[systemName])
        end)

        if success then
            uiModules[systemName] = module
            if module.Initialize then
                module.Initialize()
            end
        else
            warn("Не удалось загрузить модуль: " .. systemName)
        end
    end
end

-- Подключение событий ввода
function PlayerInputSystem.ConnectInputEvents()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        PlayerInputSystem.HandleKeyPress(input.KeyCode)
    end)

    -- Обработка мобильных жестов
    if UserInputService.TouchEnabled then
        UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
            if not gameProcessed then
                PlayerInputSystem.HandleTouchTap(touchPositions)
            end
        end)
    end
end

-- Обработка нажатия клавиш
function PlayerInputSystem.HandleKeyPress(keyCode)
    -- Обработка альтернативной клавиши ввода
    if keyCode == Enum.KeyCode.KeypadEnter then
        keyCode = Enum.KeyCode.Return
    end
    -- Инвентарь
    if keyCode == INPUT_KEYS.inventoryKey then
        PlayerInputSystem.ToggleInterface("inventory", "InventoryUISystem")
        
    -- Навыки
    elseif keyCode == INPUT_KEYS.skillKey then
        PlayerInputSystem.ToggleInterface("skills", "SkillUISystem")
        
    -- Спутники
    elseif keyCode == INPUT_KEYS.companionKey then
        PlayerInputSystem.ToggleInterface("companion", "CompanionUISystem")
        
    -- Гача
    elseif keyCode == INPUT_KEYS.gachaKey then
        PlayerInputSystem.ToggleInterface("gacha", "GachaUISystem")
        
    -- Награды
    elseif keyCode == INPUT_KEYS.rewardKey then
        PlayerInputSystem.ToggleInterface("reward", "RewardGaugeUISystem")
        
    -- Квесты
    elseif keyCode == INPUT_KEYS.questKey then
        PlayerInputSystem.ToggleInterface("quest", "QuestUISystem")
        
    -- Достижения
    elseif keyCode == INPUT_KEYS.achievementKey then
        PlayerInputSystem.ToggleInterface("achievement", "AchievementUISystem")
        
    -- Характеристики
    elseif keyCode == INPUT_KEYS.statsKey then
        PlayerInputSystem.ToggleInterface("stats", "StatUpgradeUISystem")
        
    -- Прогресс
    elseif keyCode == INPUT_KEYS.progressKey then
        PlayerInputSystem.ToggleInterface("progress", "ProgressMapUISystem")
        
    -- Уровень
    elseif keyCode == INPUT_KEYS.levelKey then
        PlayerInputSystem.ToggleInterface("level", "LevelUISystem")
        
    -- Лобби
    elseif keyCode == INPUT_KEYS.lobbyKey then
        PlayerInputSystem.ToggleInterface("lobby", "LobbyUISystem")
        
    -- Группа
    elseif keyCode == INPUT_KEYS.partyKey then
        PlayerInputSystem.ToggleInterface("party", "PartyUISystem")
        
    -- Главное меню
    elseif keyCode == INPUT_KEYS.menuKey then
        PlayerInputSystem.ToggleInterface("menu", "MenuUISystem")
        
    -- Админ панель
    elseif keyCode == INPUT_KEYS.adminKey then
        PlayerInputSystem.ToggleInterface("admin", "AdminUISystem")
        
    -- Настройки
    elseif keyCode == INPUT_KEYS.settingsKey then
        PlayerInputSystem.ToggleInterface("settings", "SettingsUISystem")
        
    -- Помощь
    elseif keyCode == INPUT_KEYS.helpKey then
        PlayerInputSystem.ToggleInterface("help", "HelpUISystem")
        
    -- Быстрые слоты
    elseif keyCode == INPUT_KEYS.quickSlot1 then
        PlayerInputSystem.UseQuickSlot(1)
    elseif keyCode == INPUT_KEYS.quickSlot2 then
        PlayerInputSystem.UseQuickSlot(2)
    elseif keyCode == INPUT_KEYS.quickSlot3 then
        PlayerInputSystem.UseQuickSlot(3)
    elseif keyCode == INPUT_KEYS.quickSlot4 then
        PlayerInputSystem.UseQuickSlot(4)
    elseif keyCode == INPUT_KEYS.quickSlot5 then
        PlayerInputSystem.UseQuickSlot(5)
    elseif keyCode == INPUT_KEYS.quickSlot6 then
        PlayerInputSystem.UseQuickSlot(6)
    elseif keyCode == INPUT_KEYS.quickSlot7 then
        PlayerInputSystem.UseQuickSlot(7)
    elseif keyCode == INPUT_KEYS.quickSlot8 then
        PlayerInputSystem.UseQuickSlot(8)
    elseif keyCode == INPUT_KEYS.quickSlot9 then
        PlayerInputSystem.UseQuickSlot(9)
    elseif keyCode == INPUT_KEYS.quickSlot0 then
        PlayerInputSystem.UseQuickSlot(0)
        
    -- Функциональные клавиши
    elseif keyCode == INPUT_KEYS.toggleUI then
        PlayerInputSystem.ToggleUI()
    elseif keyCode == INPUT_KEYS.toggleMinimap then
        PlayerInputSystem.ToggleMinimap()
    elseif keyCode == INPUT_KEYS.toggleNames then
        PlayerInputSystem.TogglePlayerNames()
    elseif keyCode == INPUT_KEYS.toggleChat then
        PlayerInputSystem.ToggleChat()
    elseif keyCode == INPUT_KEYS.screenshotKey then
        PlayerInputSystem.TakeScreenshot()
    elseif keyCode == INPUT_KEYS.fullscreenKey then
        PlayerInputSystem.ToggleFullscreen()
    end
end

-- Переключение интерфейса
function PlayerInputSystem.ToggleInterface(interfaceName, moduleName)
    local isOpen = interfaceStates[interfaceName]
    
    if isOpen then
        PlayerInputSystem.CloseInterface(interfaceName, moduleName)
    else
        PlayerInputSystem.OpenInterface(interfaceName, moduleName)
    end
end

-- Открытие интерфейса
function PlayerInputSystem.OpenInterface(interfaceName, moduleName)
    -- Закрываем другие интерфейсы (кроме HUD)
    PlayerInputSystem.CloseAllInterfaces()

    local module = uiModules[moduleName]
    if not module then return end
    if type(module.start) == "function" then
        pcall(function() module:start() end)
    end
    if module.setVisible then
        module:setVisible(true)
    elseif module.SetVisible then
        module.SetVisible(true)
    elseif module.toggle then
        module:toggle()
    elseif module.Toggle then
        module.Toggle()
    elseif module.Show then
        module.Show()
    elseif module.show then
        module.show()
    end
    interfaceStates[interfaceName] = true

    print("Открыт интерфейс: " .. interfaceName)

    -- Включаем размытие для полноэкранных интерфейсов
    if PlayerInputSystem.IsFullscreenInterface(interfaceName) then
        local BlurManager = require(script.Parent.BlurManager)
        BlurManager.EnableBlur()
    end
end

-- Закрытие интерфейса
function PlayerInputSystem.CloseInterface(interfaceName, moduleName)
    local module = uiModules[moduleName]
    if not module then return end
    if module.setVisible then
        module:setVisible(false)
    elseif module.SetVisible then
        module.SetVisible(false)
    elseif module.toggle then
        module:toggle()
    elseif module.Toggle then
        module.Toggle()
    elseif module.Hide then
        module.Hide()
    elseif module.hide then
        module.hide()
    end
    interfaceStates[interfaceName] = false

    print("Закрыт интерфейс: " .. interfaceName)

    -- Отключаем размытие
    if PlayerInputSystem.IsFullscreenInterface(interfaceName) then
        local BlurManager = require(script.Parent.BlurManager)
        BlurManager.DisableBlur()
    end
end

-- Закрытие всех интерфейсов
function PlayerInputSystem.CloseAllInterfaces()
    for interfaceName, isOpen in pairs(interfaceStates) do
        if isOpen then
            local moduleName = PlayerInputSystem.GetModuleNameForInterface(interfaceName)
            if moduleName then
                PlayerInputSystem.CloseInterface(interfaceName, moduleName)
            end
        end
    end
end

-- Проверка, является ли интерфейс полноэкранным
function PlayerInputSystem.IsFullscreenInterface(interfaceName)
    local fullscreenInterfaces = {
        "inventory", "skills", "companion", "gacha", "quest",
        "achievement", "progress", "menu", "admin", "settings"
    }
    
    for _, name in ipairs(fullscreenInterfaces) do
        if name == interfaceName then
            return true
        end
    end
    
    return false
end

-- Получение имени модуля для интерфейса
function PlayerInputSystem.GetModuleNameForInterface(interfaceName)
    local interfaceToModule = {
        inventory = "InventoryUISystem",
        skills = "SkillUISystem",
        companion = "CompanionUISystem",
        gacha = "GachaUISystem",
        reward = "RewardGaugeUISystem",
        quest = "QuestUISystem",
        achievement = "AchievementUISystem",
        stats = "StatUpgradeUISystem",
        progress = "ProgressMapUISystem",
        level = "LevelUISystem",
        lobby = "LobbyUISystem",
        party = "PartyUISystem",
        menu = "MenuUISystem",
        admin = "AdminUISystem",
        settings = "SettingsUISystem",
        help = "HelpUISystem",
    }
    
    return interfaceToModule[interfaceName]
end

-- Использование быстрого слота
function PlayerInputSystem.UseQuickSlot(slotNumber)
    local hudSystem = uiModules["HudSystem"]
    if hudSystem and hudSystem.UseQuickSlot then
        hudSystem.UseQuickSlot(slotNumber)
    end
end

-- Настройка мобильных элементов управления
function PlayerInputSystem.SetupMobileControls()
    if not UserInputService.TouchEnabled then return end
    
    -- Создание мобильных кнопок для основных функций
    local mobileButtons = {
        {name = "Inventory", key = "inventoryKey", position = UDim2.new(1, -60, 0, 10)},
        {name = "Skills", key = "skillKey", position = UDim2.new(1, -60, 0, 80)},
        {name = "Quest", key = "questKey", position = UDim2.new(1, -60, 0, 150)},
        {name = "Menu", key = "menuKey", position = UDim2.new(1, -60, 0, 220)},
    }
    
    for _, buttonData in ipairs(mobileButtons) do
        PlayerInputSystem.CreateMobileButton(buttonData)
    end
end

-- Создание мобильной кнопки
function PlayerInputSystem.CreateMobileButton(buttonData)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = playerGui:FindFirstChild("MobileControls")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MobileControls"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui
    end
    
    local button = Instance.new("TextButton")
    button.Name = buttonData.name .. "Button"
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = buttonData.position
    button.Text = buttonData.name:sub(1, 1)
    button.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    -- Используем шрифт из темы для единообразия
    button.Font = UITheme.Fonts.Bold
    button.TextSize = 18
    button.Parent = screenGui
    
    local UITheme = require(script.Parent.UITheme)
    UITheme.CreateCorner(8).Parent = button
    
    button.MouseButton1Click:Connect(function()
        PlayerInputSystem.HandleKeyPress(INPUT_KEYS[buttonData.key])
    end)
end

-- Обработка тапов на мобильных устройствах
function PlayerInputSystem.HandleTouchTap(touchPositions)
    -- Здесь можно добавить обработку жестов
    print("Touch tap detected at positions:", touchPositions)
end

-- Переключение UI
function PlayerInputSystem.ToggleUI()
    local hudSystem = uiModules["HudSystem"]
    if hudSystem and hudSystem.ToggleVisibility then
        hudSystem.ToggleVisibility()
    end
end

-- Переключение миникарты
function PlayerInputSystem.ToggleMinimap()
    local hudSystem = uiModules["HudSystem"]
    if hudSystem and hudSystem.ToggleMinimap then
        hudSystem.ToggleMinimap()
    end
end

-- Переключение имён игроков
function PlayerInputSystem.TogglePlayerNames()
    -- Здесь код для переключения отображения имён игроков
    print("Toggle player names")
end

-- Переключение чата
function PlayerInputSystem.ToggleChat()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
end

-- Снимок экрана
function PlayerInputSystem.TakeScreenshot()
    print("Taking screenshot...")
    -- Здесь код для создания снимка экрана
end

-- Переключение полноэкранного режима
function PlayerInputSystem.ToggleFullscreen()
    GuiService:ToggleFullscreen()
end

-- Получение текущего состояния интерфейса
function PlayerInputSystem.GetInterfaceState(interfaceName)
    return interfaceStates[interfaceName] or false
end

-- Установка состояния интерфейса
function PlayerInputSystem.SetInterfaceState(interfaceName, state)
    interfaceStates[interfaceName] = state
end

-- Получение назначенных клавиш
function PlayerInputSystem.GetInputKeys()
    return INPUT_KEYS
end

-- Изменение назначения клавиши
function PlayerInputSystem.SetInputKey(keyName, newKeyCode)
    if INPUT_KEYS[keyName] then
        INPUT_KEYS[keyName] = newKeyCode
        print("Клавиша " .. keyName .. " изменена на " .. newKeyCode.Name)
    end
end

-- Очистка ресурсов
function PlayerInputSystem.Cleanup()
    for _, module in pairs(uiModules) do
        if module.Cleanup then
            module.Cleanup()
        end
    end
    
    uiModules = {}
    
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local mobileControls = playerGui:FindFirstChild("MobileControls")
    if mobileControls then
        mobileControls:Destroy()
    end
end

return PlayerInputSystem
