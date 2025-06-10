-- Пример клиентского скрипта (LocalScript)
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventManager = require(game.ReplicatedStorage.Modules.EventManager)

local attackEvent = EventManager.Get("PlayerAttack")

-- Если клиент хочет использовать настройки из PlayerConfig,
-- можно не передавать параметры (или передать nil).
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		attackEvent:FireServer()  -- Используются параметры по умолчанию из PlayerConfig
		-- Если же хочешь передать конкретные параметры:
		-- attackEvent:FireServer(15, 2, 25)
	end
end)
