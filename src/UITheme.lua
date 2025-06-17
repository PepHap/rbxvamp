local UITheme = {}

-- Base colors inspired by Genshin Impact's UI
UITheme.colors = {
    windowBackground = Color3 and Color3.fromRGB and Color3.fromRGB(20, 20, 30) or {r=20,g=20,b=30},
    buttonBackground = Color3 and Color3.fromRGB and Color3.fromRGB(40, 60, 90) or {r=40,g=60,b=90},
    buttonText = Color3 and Color3.fromRGB and Color3.fromRGB(255, 255, 255) or {r=1,g=1,b=1},
    labelText = Color3 and Color3.fromRGB and Color3.fromRGB(220, 220, 220) or {r=220,g=220,b=220},
    -- Slightly brighter background when hovering buttons
    buttonHover = Color3 and Color3.fromRGB and Color3.fromRGB(60, 80, 120) or {r=60,g=80,b=120},
}

-- Fallback font if Enum.Font is unavailable
UITheme.font = Enum and Enum.Font and Enum.Font.GothamBold

UITheme.cornerRadius = 8

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
        BackgroundColor3 = UITheme.colors.windowBackground,
    })
    addCorner(frame)
end

function UITheme.styleButton(btn)
    assign(btn, {
        Font = UITheme.font,
        TextColor3 = UITheme.colors.buttonText,
        BackgroundColor3 = UITheme.colors.buttonBackground,
        AutoButtonColor = false,
    })
    addCorner(btn)
end

function UITheme.styleLabel(lbl)
    assign(lbl, {
        Font = UITheme.font,
        TextColor3 = UITheme.colors.labelText,
        BackgroundTransparency = lbl.BackgroundTransparency or 1,
    })
    addCorner(lbl)
end

return UITheme
