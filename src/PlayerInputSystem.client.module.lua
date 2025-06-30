-- PlayerInputSystem.client.module.lua
-- Управление вводом и назначением клавиш для открытия различных интерфейсов

local PlayerInputSystem = {}

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MessageUI = require(script.Parent:WaitForChild("MessageUI"))
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
local GachaUI = require(script.Parent:WaitForChild("GachaUI"))
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local WindowTabs = require(script.Parent:WaitForChild("WindowTabs"))

local INPUT_KEYS = {

    -- Дополнительные клавиши
    -- Используем Return, так как "Enter" отсутствует в Enum.KeyCode
    -- Дополнительно обрабатываем KeypadEnter для совместимости
    chatKey = Enum.KeyCode.Return,
    screenshotKey = Enum.KeyCode.F12,
    fullscreenKey = Enum.KeyCode.F11,
    settingsKey = Enum.KeyCode.Escape,
    helpKey = Enum.KeyCode.F1,

    -- Функциональные клавиши
    autoAttack = Enum.KeyCode.Space,
    interact = Enum.KeyCode.F,
    run = Enum.KeyCode.LeftShift,
    walk = Enum.KeyCode.LeftControl,
    jump = Enum.KeyCode.Space,

    -- Управление стандартными функциями
    toggleChat = Enum.KeyCode.F5,
    inventory = Enum.KeyCode.M,
    gacha = Enum.KeyCode.N,
}

-- Инициализация системы ввода
function PlayerInputSystem.Initialize()
    -- Ensure the ScreenGui is available before initializing UI modules
    -- https://create.roblox.com/docs/reference/engine/classes/ScreenGui
    UIBridge.waitForGui()
    InventoryUI.init()
    GachaUI.init()
    WindowTabs.init()
    MessageUI.init()
    PlayerInputSystem.ConnectInputEvents()

    print("PlayerInputSystem инициализирован")
end

-- Provide a start method used by ClientGameRunner to initialize the
-- input system. This simply delegates to ``Initialize`` for backward
-- compatibility with older code.
function PlayerInputSystem:start()
    self.Initialize()
end

-- Подключение событий ввода
function PlayerInputSystem.ConnectInputEvents()
    -- https://create.roblox.com/docs/reference/engine/classes/UserInputService#InputBegan
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        PlayerInputSystem.HandleKeyPress(input.KeyCode)
    end)

end

-- Обработка нажатия клавиш
function PlayerInputSystem.HandleKeyPress(keyCode)
    -- Обработка альтернативной клавиши ввода
    if keyCode == Enum.KeyCode.KeypadEnter then
        keyCode = Enum.KeyCode.Return
    end
    if keyCode == INPUT_KEYS.chatKey then
        PlayerInputSystem.ToggleChat()
    elseif keyCode == INPUT_KEYS.screenshotKey then
        PlayerInputSystem.TakeScreenshot()
    elseif keyCode == INPUT_KEYS.fullscreenKey then
        PlayerInputSystem.ToggleFullscreen()
    elseif keyCode == INPUT_KEYS.inventory then
        WindowTabs.activateInventory()
    elseif keyCode == INPUT_KEYS.gacha then
        WindowTabs.activateSummon()
    end
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

return PlayerInputSystem
