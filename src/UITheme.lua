local UITheme = {}

-- Base colors inspired by Genshin Impact's UI
UITheme.colors = {
    windowBackground = Color3 and Color3.fromRGB and Color3.fromRGB(35, 40, 55) or {r=35,g=40,b=55},
    buttonBackground = Color3 and Color3.fromRGB and Color3.fromRGB(70, 100, 140) or {r=70,g=100,b=140},
    buttonText = Color3 and Color3.fromRGB and Color3.fromRGB(255, 255, 255) or {r=1,g=1,b=1},
    labelText = Color3 and Color3.fromRGB and Color3.fromRGB(240, 240, 240) or {r=240,g=240,b=240},
    -- Slightly brighter background when hovering buttons
    buttonHover = Color3 and Color3.fromRGB and Color3.fromRGB(100, 140, 190) or {r=100,g=140,b=190},
    -- Accent color used for selected buttons or highlighted elements
    highlight = Color3 and Color3.fromRGB and Color3.fromRGB(100, 170, 230) or {r=100,g=170,b=230},
    progressBar = Color3 and Color3.fromRGB and Color3.fromRGB(100, 170, 255) or {r=100,g=170,b=255},
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

UITheme.cornerRadius = 12

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
    addCorner(frame)
end

function UITheme.styleButton(btn)
    assign(btn, {
        Font = UITheme.font,
        TextColor3 = toColor3(UITheme.colors.buttonText),
        BackgroundColor3 = toColor3(UITheme.colors.buttonBackground),
        AutoButtonColor = false,
    })
    addCorner(btn)
end

function UITheme.styleLabel(lbl)
    assign(lbl, {
        Font = UITheme.font,
        TextColor3 = toColor3(UITheme.colors.labelText),
        BackgroundTransparency = lbl.BackgroundTransparency or 1,
    })
    addCorner(lbl)
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

return UITheme
