-- UITheme.lua
-- Модуль содержит палитру цветов и стили оформления для всех элементов GUI

local UITheme = {}

-- Основная цветовая палитра
UITheme.Colors = {
    -- Основные цвета интерфейса
    Primary = Color3.fromRGB(59, 130, 246),      -- Синий
    Secondary = Color3.fromRGB(168, 85, 247),    -- Фиолетовый
    Success = Color3.fromRGB(34, 197, 94),       -- Зелёный
    Warning = Color3.fromRGB(245, 158, 11),      -- Жёлтый
    Danger = Color3.fromRGB(239, 68, 68),        -- Красный

    -- Фоновые цвета
    BackgroundDark = Color3.fromRGB(17, 24, 39),    -- Тёмный фон
    BackgroundMedium = Color3.fromRGB(31, 41, 55),  -- Средний фон
    BackgroundLight = Color3.fromRGB(55, 65, 81),   -- Светлый фон

    -- Цвета границ
    BorderDark = Color3.fromRGB(75, 85, 99),
    BorderLight = Color3.fromRGB(156, 163, 175),

    -- Цвета текста
    TextPrimary = Color3.fromRGB(255, 255, 255),    -- Белый
    TextSecondary = Color3.fromRGB(209, 213, 219),  -- Светло-серый
    TextMuted = Color3.fromRGB(156, 163, 175),      -- Серый
    TextDisabled = Color3.fromRGB(107, 114, 128),   -- Тёмно-серый

    -- Цвета редкости предметов
    RarityCommon = Color3.fromRGB(156, 163, 175),    -- Серый
    RarityUncommon = Color3.fromRGB(34, 197, 94),    -- Зелёный
    RarityRare = Color3.fromRGB(59, 130, 246),       -- Синий
    RarityEpic = Color3.fromRGB(168, 85, 247),       -- Фиолетовый
    RarityLegendary = Color3.fromRGB(245, 158, 11),  -- Золотой

    -- Цвета валют
    Gold = Color3.fromRGB(245, 158, 11),
    Crystals = Color3.fromRGB(59, 130, 246),
    Souls = Color3.fromRGB(168, 85, 247),
    Keys = Color3.fromRGB(239, 68, 68),

    -- Цвета состояний
    Health = Color3.fromRGB(239, 68, 68),
    Mana = Color3.fromRGB(59, 130, 246),
    Stamina = Color3.fromRGB(245, 158, 11),
    Experience = Color3.fromRGB(34, 197, 94),

    -- Прозрачность
    Transparent = Color3.fromRGB(0, 0, 0),
    SemiTransparent = Color3.fromRGB(0, 0, 0),
}

-- Размеры и отступы
UITheme.Sizes = {
    -- Стандартные размеры кнопок
    ButtonSmall = UDim2.new(0, 80, 0, 30),
    ButtonMedium = UDim2.new(0, 120, 0, 40),
    ButtonLarge = UDim2.new(0, 160, 0, 50),

    -- Размеры окон
    WindowSmall = UDim2.new(0, 400, 0, 300),
    WindowMedium = UDim2.new(0, 600, 0, 450),
    WindowLarge = UDim2.new(0, 800, 0, 600),
    WindowFullscreen = UDim2.new(0.9, 0, 0.9, 0),

    -- Размеры слотов
    SlotSmall = UDim2.new(0, 40, 0, 40),
    SlotMedium = UDim2.new(0, 60, 0, 60),
    SlotLarge = UDim2.new(0, 80, 0, 80),

    -- Отступы
    PaddingSmall = UDim.new(0, 5),
    PaddingMedium = UDim.new(0, 10),
    PaddingLarge = UDim.new(0, 20),

    -- Размеры текста
    TextSmall = 12,
    TextMedium = 14,
    TextLarge = 18,
    TextTitle = 24,
    TextHeader = 32,
}

-- Шрифты
UITheme.Fonts = {
    Regular = Enum.Font.Gotham,
    Bold = Enum.Font.GothamBold,
    SemiBold = Enum.Font.GothamSemibold,
    -- GothamLight отсутствует, поэтому используем SourceSans как облегчённый вариант
    Light = Enum.Font.SourceSans,
    Mono = Enum.Font.RobotoMono,
}

-- Анимации
UITheme.Animations = {
    FastTween = 0.15,
    MediumTween = 0.3,
    SlowTween = 0.5,

    EasingIn = Enum.EasingStyle.Quad,
    EasingOut = Enum.EasingStyle.Quad,
    EasingInOut = Enum.EasingStyle.Quart,
}

-- Стили для различных типов элементов
UITheme.Styles = {
    Window = {
        BackgroundColor3 = UITheme.Colors.BackgroundDark,
        BorderColor3 = UITheme.Colors.BorderDark,
        BorderSizePixel = 2,
    },

    Panel = {
        BackgroundColor3 = UITheme.Colors.BackgroundMedium,
        BorderColor3 = UITheme.Colors.BorderDark,
        BorderSizePixel = 1,
    },

    Button = {
        BackgroundColor3 = UITheme.Colors.Primary,
        BorderColor3 = UITheme.Colors.BorderLight,
        BorderSizePixel = 1,
        TextColor3 = UITheme.Colors.TextPrimary,
        Font = UITheme.Fonts.SemiBold,
        TextSize = UITheme.Sizes.TextMedium,
    },

    ButtonHover = {
        BackgroundColor3 = Color3.fromRGB(37, 99, 235),
    },

    ButtonDisabled = {
        BackgroundColor3 = UITheme.Colors.TextDisabled,
        TextColor3 = UITheme.Colors.TextMuted,
    },

    Input = {
        BackgroundColor3 = UITheme.Colors.BackgroundLight,
        BorderColor3 = UITheme.Colors.BorderDark,
        BorderSizePixel = 1,
        TextColor3 = UITheme.Colors.TextPrimary,
        Font = UITheme.Fonts.Regular,
        TextSize = UITheme.Sizes.TextMedium,
    },

    Label = {
        BackgroundTransparency = 1,
        TextColor3 = UITheme.Colors.TextPrimary,
        Font = UITheme.Fonts.Regular,
        TextSize = UITheme.Sizes.TextMedium,
    },

    Title = {
        BackgroundTransparency = 1,
        TextColor3 = UITheme.Colors.Warning,
        Font = UITheme.Fonts.Bold,
        TextSize = UITheme.Sizes.TextTitle,
    },

    Slot = {
        BackgroundColor3 = UITheme.Colors.BackgroundLight,
        BorderColor3 = UITheme.Colors.BorderDark,
        BorderSizePixel = 2,
    },

    ProgressBar = {
        BackgroundColor3 = UITheme.Colors.BackgroundLight,
        BorderColor3 = UITheme.Colors.BorderDark,
        BorderSizePixel = 1,
    },

    ProgressFill = {
        BorderSizePixel = 0,
    },

    ScrollFrame = {
        BackgroundColor3 = UITheme.Colors.BackgroundMedium,
        BorderSizePixel = 0,
        ScrollBarImageColor3 = UITheme.Colors.Primary,
        ScrollBarThickness = 8,
    },
}

-- Функции для получения цветов редкости
function UITheme.GetRarityColor(rarity)
    local rarityColors = {
        common = UITheme.Colors.RarityCommon,
        uncommon = UITheme.Colors.RarityUncommon,
        rare = UITheme.Colors.RarityRare,
        epic = UITheme.Colors.RarityEpic,
        legendary = UITheme.Colors.RarityLegendary,
    }
    return rarityColors[rarity] or UITheme.Colors.RarityCommon
end

-- Функция для создания градиента
function UITheme.CreateGradient(startColor, endColor, direction)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(startColor, endColor)

    if direction == "vertical" then
        gradient.Rotation = 90
    elseif direction == "diagonal" then
        gradient.Rotation = 45
    end

    return gradient
end

-- Функция для применения стиля к элементу
function UITheme.ApplyStyle(element, styleName)
    local style = UITheme.Styles[styleName]
    if not style then
        warn("Стиль '" .. styleName .. "' не найден в UITheme")
        return
    end

    for property, value in pairs(style) do
        element[property] = value
    end
end

-- Функция для создания тени
function UITheme.CreateShadow(parent, offset, blur)
    offset = offset or Vector2.new(2, 2)
    blur = blur or 4

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, blur * 2, 1, blur * 2)
    shadow.Position = UDim2.new(0, offset.X - blur, 0, offset.Y - blur)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.3
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent.Parent

    return shadow
end

-- Функция для создания скруглённых углов
function UITheme.CreateCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

-- Функция для создания отступов
function UITheme.CreatePadding(size)
    local padding = Instance.new("UIPadding")
    local paddingSize = size or UITheme.Sizes.PaddingMedium

    padding.PaddingTop = paddingSize
    padding.PaddingBottom = paddingSize
    padding.PaddingLeft = paddingSize
    padding.PaddingRight = paddingSize

    return padding
end

-- Функция для создания обводки
function UITheme.CreateStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or UITheme.Colors.BorderDark
    stroke.Thickness = thickness or 1
    return stroke
end

-- Локальные темы для разных локаций
UITheme.LocationThemes = {
    forest = {
        primary = Color3.fromRGB(34, 197, 94),
        background = Color3.fromRGB(20, 30, 20),
    },

    desert = {
        primary = Color3.fromRGB(245, 158, 11),
        background = Color3.fromRGB(40, 30, 20),
    },

    ice = {
        primary = Color3.fromRGB(59, 130, 246),
        background = Color3.fromRGB(20, 25, 35),
    },

    volcano = {
        primary = Color3.fromRGB(239, 68, 68),
        background = Color3.fromRGB(40, 20, 20),
    },

    shadow = {
        primary = Color3.fromRGB(168, 85, 247),
        background = Color3.fromRGB(25, 20, 35),
    },
}

-- Функция для применения темы локации
function UITheme.ApplyLocationTheme(locationName)
    local theme = UITheme.LocationThemes[locationName]
    if theme then
        UITheme.Colors.Primary = theme.primary
        UITheme.Colors.BackgroundDark = theme.background
        UITheme.Styles.Button.BackgroundColor3 = theme.primary
    end
end

-- Совместимость со старым API
function UITheme.styleWindow(frame)
    UITheme.ApplyStyle(frame, "Window")
    UITheme.CreateCorner(8).Parent = frame
end

function UITheme.styleButton(btn)
    UITheme.ApplyStyle(btn, "Button")
    UITheme.CreateCorner(6).Parent = btn
end

function UITheme.styleLabel(lbl)
    UITheme.ApplyStyle(lbl, "Label")
end

function UITheme.styleImageButton(btn)
    UITheme.ApplyStyle(btn, "Button")
    UITheme.CreateCorner(6).Parent = btn
end

function UITheme.styleInput(input)
    UITheme.ApplyStyle(input, "Input")
    UITheme.CreateCorner(6).Parent = input
end

function UITheme.styleProgressBar(bar)
    UITheme.ApplyStyle(bar, "ProgressBar")
    UITheme.CreateCorner(4).Parent = bar
end

function UITheme.getHealthColor(ratio)
    local hi = UITheme.Colors.Success
    local lo = UITheme.Colors.Danger
    ratio = math.clamp(ratio or 1, 0, 1)
    local r = lo.R + (hi.R - lo.R) * ratio
    local g = lo.G + (hi.G - lo.G) * ratio
    local b = lo.B + (hi.B - lo.B) * ratio
    return Color3.new(r, g, b)
end

return UITheme
