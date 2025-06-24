local UITheme = {}

-- Base colors inspired by Genshin Impact's UI
UITheme.colors = {
    windowBackground = Color3 and Color3.fromRGB and Color3.fromRGB(40, 45, 60) or {r=40,g=45,b=60},
    windowBackground2 = Color3 and Color3.fromRGB and Color3.fromRGB(30, 35, 50) or {r=30,g=35,b=50},
    buttonBackground = Color3 and Color3.fromRGB and Color3.fromRGB(50, 120, 220) or {r=50,g=120,b=220},
    buttonText = Color3 and Color3.fromRGB and Color3.fromRGB(255, 255, 255) or {r=1,g=1,b=1},
    labelText = Color3 and Color3.fromRGB and Color3.fromRGB(235, 235, 235) or {r=235,g=235,b=235},
    -- Slightly brighter background when hovering buttons
    buttonHover = Color3 and Color3.fromRGB and Color3.fromRGB(80, 150, 240) or {r=80,g=150,b=240},
    -- Accent color used for selected buttons or highlighted elements
    highlight = Color3 and Color3.fromRGB and Color3.fromRGB(100, 200, 255) or {r=100,g=200,b=255},
    progressBar = Color3 and Color3.fromRGB and Color3.fromRGB(100, 200, 255) or {r=100,g=200,b=255},
    -- Color for full player health
    healthHigh = Color3 and Color3.fromRGB and Color3.fromRGB(80, 220, 80) or {r=80,g=220,b=80},
    -- Color for very low player health
    healthLow = Color3 and Color3.fromRGB and Color3.fromRGB(220, 80, 80) or {r=220,g=80,b=80},
}

UITheme.rarityColors = {
    C  = Color3 and Color3.fromRGB and Color3.fromRGB(200, 200, 200) or {r=200,g=200,b=200},
    D  = Color3 and Color3.fromRGB and Color3.fromRGB(180, 220, 255) or {r=180,g=220,b=255},
    B  = Color3 and Color3.fromRGB and Color3.fromRGB(140, 255, 140) or {r=140,g=255,b=140},
    A  = Color3 and Color3.fromRGB and Color3.fromRGB(255, 200, 120) or {r=255,g=200,b=120},
    S  = Color3 and Color3.fromRGB and Color3.fromRGB(255, 150, 150) or {r=255,g=150,b=150},
    SS = Color3 and Color3.fromRGB and Color3.fromRGB(255, 100, 255) or {r=255,g=100,b=255},
    SSS= Color3 and Color3.fromRGB and Color3.fromRGB(255, 220, 40) or {r=255,g=220,b=40},
}

-- Fallback font if Enum.Font is unavailable
UITheme.font = Enum and Enum.Font and Enum.Font.GothamBold

UITheme.cornerRadius = 16

-- Convert RGB table values returned in test environments to actual Color3
-- values when running inside Roblox. This prevents type mismatches when
-- assigning colors to GUI properties or using TweenService.
local function toColor3(value)
    if typeof and typeof(value) == "Color3" then
        return value
    end
    if type(value) == "table" and value.r and value.g and value.b and Color3 then
        if Color3.fromRGB then
            return Color3.fromRGB(value.r, value.g, value.b)
        elseif Color3.new then
            return Color3.new(value.r/255, value.g/255, value.b/255)
        end
    end
    return value
end

local function lighten(col, factor)
    local c = toColor3(col)
    factor = math.clamp and math.clamp(factor or 0, 0, 1) or math.max(0, math.min(factor or 0, 1))
    if typeof and typeof(c) == "Color3" then
        local r = c.R + (1 - c.R) * factor
        local g = c.G + (1 - c.G) * factor
        local b = c.B + (1 - c.B) * factor
        return Color3.new(r, g, b)
    elseif type(c) == "table" then
        return {
            r = c.r + (255 - c.r) * factor,
            g = c.g + (255 - c.g) * factor,
            b = c.b + (255 - c.b) * factor,
        }
    end
    return c
end

local function addCorner(obj)
    if not obj then return end
    local radius = UITheme.cornerRadius or 0
    if typeof and typeof(obj) == "Instance" and Instance and type(Instance.new) == "function" then
        local ok, corner = pcall(function()
            return Instance.new("UICorner")
        end)
        if ok and corner then
            corner.CornerRadius = UDim.new(0, radius)
            corner.Parent = obj
        end
    else
        obj.cornerRadius = radius
    end
end

local function assign(target, props)
    if type(target) ~= "table" and (typeof and typeof(target) ~= "Instance") then
        return
    end
    for k, v in pairs(props) do
        local ok, _ = pcall(function()
            target[k] = v
        end)
        if not ok and type(target) == "table" then
            target[k] = v
        end
    end
end

function UITheme.styleWindow(frame)
    assign(frame, {
        BackgroundTransparency = 0.1,
        BackgroundColor3 = toColor3(UITheme.colors.windowBackground),
    })
    if typeof and typeof(frame) == "Instance" and Instance and type(Instance.new) == "function" then
        local ok, grad = pcall(function()
            return Instance.new("UIGradient")
        end)
        if ok and grad and ColorSequence then
            local c1 = toColor3(UITheme.colors.windowBackground)
            local c2 = toColor3(UITheme.colors.windowBackground2)
            grad.Color = ColorSequence.new(c1, c2)
            grad.Parent = frame
        end
        local okStroke, stroke = pcall(function()
            return Instance.new("UIStroke")
        end)
        if okStroke and stroke then
            stroke.Color = toColor3(UITheme.colors.highlight)
            stroke.Thickness = 1
            stroke.Parent = frame
        end
    else
        frame.gradient = {UITheme.colors.windowBackground, UITheme.colors.windowBackground2}
        frame.strokeColor = UITheme.colors.highlight
    end
    addCorner(frame)
end

function UITheme.styleButton(btn)
    assign(btn, {
        Font = UITheme.font,
        TextColor3 = toColor3(UITheme.colors.buttonText),
        BackgroundColor3 = toColor3(UITheme.colors.buttonBackground),
        AutoButtonColor = false,
        TextScaled = true,
    })
    addCorner(btn)
    if typeof and typeof(btn) == "Instance" and Instance and type(Instance.new) == "function" then
        local ok, stroke = pcall(function()
            return Instance.new("UIStroke")
        end)
        if ok and stroke then
            stroke.Color = toColor3(UITheme.colors.highlight)
            stroke.Thickness = 1
            stroke.Parent = btn
        end
    else
        btn.strokeColor = UITheme.colors.highlight
    end
end

function UITheme.styleLabel(lbl)
    assign(lbl, {
        Font = UITheme.font,
        TextColor3 = toColor3(UITheme.colors.labelText),
        BackgroundTransparency = lbl.BackgroundTransparency or 1,
        TextScaled = true,
    })
    addCorner(lbl)
end

---Styles an ImageButton with rounded corners and highlight stroke.
-- @param btn table|Instance ImageButton object
function UITheme.styleImageButton(btn)
    assign(btn, {
        BackgroundColor3 = toColor3(UITheme.colors.buttonBackground),
        AutoButtonColor = false,
    })
    addCorner(btn)
    if typeof and typeof(btn) == "Instance" and Instance and type(Instance.new) == "function" then
        local ok, stroke = pcall(function()
            return Instance.new("UIStroke")
        end)
        if ok and stroke then
            stroke.Color = toColor3(UITheme.colors.highlight)
            stroke.Thickness = 1
            stroke.Parent = btn
        end
    else
        btn.strokeColor = UITheme.colors.highlight
    end
end

---Styles an input TextBox control with the theme colors.
-- Adds consistent font and rounded corners similar to buttons.
-- @param input table|Instance TextBox object
function UITheme.styleInput(input)
    assign(input, {
        Font = UITheme.font,
        TextColor3 = toColor3(UITheme.colors.labelText),
        BackgroundColor3 = toColor3(UITheme.colors.buttonBackground),
    })
    addCorner(input)
end

---Styles a simple progress bar frame.
--@param bar table|Instance progress bar container
function UITheme.styleProgressBar(bar)
    assign(bar, {
        BackgroundTransparency = 0.1,
        BackgroundColor3 = toColor3(UITheme.colors.windowBackground2),
    })
    addCorner(bar)
    if typeof and typeof(bar) == "Instance" and Instance and type(Instance.new) == "function" then
        local okGrad, grad = pcall(function()
            return Instance.new("UIGradient")
        end)
        if okGrad and grad and ColorSequence then
            local start = lighten(UITheme.colors.progressBar, 0.3)
            local finish = toColor3(UITheme.colors.progressBar)
            grad.Color = ColorSequence.new(toColor3(start), finish)
            grad.Parent = bar
        end
        local okStroke, stroke = pcall(function()
            return Instance.new("UIStroke")
        end)
        if okStroke and stroke then
            stroke.Color = toColor3(UITheme.colors.highlight)
            stroke.Thickness = 1
            stroke.Parent = bar
        end
    else
        bar.strokeColor = UITheme.colors.highlight
    end
end

---Returns an interpolated color from green to red based on the health ratio.
-- @param ratio number value between 0 and 1 representing current HP
function UITheme.getHealthColor(ratio)
    ratio = math.clamp and math.clamp(ratio or 1, 0, 1) or math.max(0, math.min(ratio or 1, 1))
    local hi = toColor3(UITheme.colors.healthHigh)
    local lo = toColor3(UITheme.colors.healthLow)
    if Color3 and Color3.new and typeof then
        local r = lo.R + (hi.R - lo.R) * ratio
        local g = lo.G + (hi.G - lo.G) * ratio
        local b = lo.B + (hi.B - lo.B) * ratio
        return Color3.new(r, g, b)
    end
    return {
        r = lo.r + (hi.r - lo.r) * ratio,
        g = lo.g + (hi.g - lo.g) * ratio,
        b = lo.b + (hi.b - lo.b) * ratio,
    }
end

return UITheme
