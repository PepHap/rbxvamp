local UITheme = {}

-- Base colors inspired by Genshin Impact's UI
UITheme.colors = {
    windowBackground = Color3 and Color3.fromRGB and Color3.fromRGB(20, 20, 30) or {r=20,g=20,b=30},
    buttonBackground = Color3 and Color3.fromRGB and Color3.fromRGB(40, 60, 90) or {r=40,g=60,b=90},
    buttonText = Color3 and Color3.fromRGB and Color3.fromRGB(255, 255, 255) or {r=1,g=1,b=1},
    labelText = Color3 and Color3.fromRGB and Color3.fromRGB(220, 220, 220) or {r=220,g=220,b=220},
}

-- Fallback font if Enum.Font is unavailable
UITheme.font = Enum and Enum.Font and Enum.Font.GothamBold

local function assign(target, props)
    if type(target) ~= "table" and (typeof and typeof(target) ~= "Instance") then
        return
    end
    for k, v in pairs(props) do
        if target[k] ~= nil then
            target[k] = v
        end
    end
end

function UITheme.styleWindow(frame)
    assign(frame, {
        BackgroundTransparency = 0.1,
        BackgroundColor3 = UITheme.colors.windowBackground,
    })
end

function UITheme.styleButton(btn)
    assign(btn, {
        Font = UITheme.font,
        TextColor3 = UITheme.colors.buttonText,
        BackgroundColor3 = UITheme.colors.buttonBackground,
        AutoButtonColor = false,
    })
end

function UITheme.styleLabel(lbl)
    assign(lbl, {
        Font = UITheme.font,
        TextColor3 = UITheme.colors.labelText,
        BackgroundTransparency = lbl.BackgroundTransparency or 1,
    })
end

return UITheme
