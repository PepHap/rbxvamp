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

return BlurManager
