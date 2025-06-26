-- BlurManager.lua
-- Управляет эффектом размытия при открытии окон

local BlurManager = {}
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Настройки размытия
local BLUR_SIZE = 24
local BLUR_TRANSPARENCY = 0.5
local BLUR_DURATION = 0.3

-- Эффект размытия
local blurEffect = nil
local currentBlurTween = nil
local isBlurred = false

-- Инициализация эффекта размытия
function BlurManager.Initialize()
    if not blurEffect then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "UIBlurEffect"
        blurEffect.Size = 0
        blurEffect.Parent = Lighting
    end
end

-- Включение размытия
function BlurManager.EnableBlur(duration, size)
    BlurManager.Initialize()

    duration = duration or BLUR_DURATION
    size = size or BLUR_SIZE

    if currentBlurTween then
        currentBlurTween:Cancel()
    end

    currentBlurTween = TweenService:Create(blurEffect,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = size}
    )

    currentBlurTween:Play()
    isBlurred = true

    return currentBlurTween
end

-- Отключение размытия
function BlurManager.DisableBlur(duration)
    if not blurEffect then return end

    duration = duration or BLUR_DURATION

    if currentBlurTween then
        currentBlurTween:Cancel()
    end

    currentBlurTween = TweenService:Create(blurEffect,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = 0}
    )

    currentBlurTween:Play()
    isBlurred = false

    return currentBlurTween
end

-- Проверка состояния размытия
function BlurManager.IsBlurred()
    return isBlurred
end

-- Получение силы размытия
function BlurManager.GetBlurSize()
    return blurEffect and blurEffect.Size or 0
end

-- Установка силы размытия без анимации
function BlurManager.SetBlurSize(size)
    BlurManager.Initialize()
    blurEffect.Size = size
    isBlurred = size > 0
end

-- Очистка ресурсов
function BlurManager.Cleanup()
    if currentBlurTween then
        currentBlurTween:Cancel()
        currentBlurTween = nil
    end

    if blurEffect then
        blurEffect:Destroy()
        blurEffect = nil
    end

    isBlurred = false
end

--[[
Compatibility layer for older code expecting object-method style API
The new BlurManager exposes functions like EnableBlur/DisableBlur while
existing UI modules still invoke methods "add", "remove", "reset" and
"isActive" using the colon operator.  Provide thin wrappers mapping the
old names to the new functionality so legacy modules continue to work
without modification.
--]]

---Enables blur effect (legacy method).
--@param duration number? tween time
--@param size number? blur strength
function BlurManager:add(duration, size)
    return BlurManager.EnableBlur(duration, size)
end

---Disables blur effect (legacy method).
--@param duration number? tween time
function BlurManager:remove(duration)
    return BlurManager.DisableBlur(duration)
end

---Returns whether blur is active (legacy method).
--@return boolean
function BlurManager:isActive()
    return BlurManager.IsBlurred()
end

---Fully clears blur state (legacy method).
function BlurManager:reset()
    BlurManager.DisableBlur(0)
    BlurManager.Cleanup()
end

return BlurManager
