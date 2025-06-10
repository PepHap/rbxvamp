-- LocalScript (клиентская часть)
local Players = game:GetService("Players")
local player = Players.LocalPlayer -- Получаем текущего игрока

-- Получаем RemoteEvent
local remoteEvent = game.ReplicatedStorage:WaitForChild("FirePunch")

-- Функция, которая отправляет серверу запрос на удар
local function onKeyDown(key)
	if key == "f" then -- Если нажата клавиша "F"
		-- Вызываем удаленный ивент, чтобы сообщить серверу о ударе
		remoteEvent:FireServer()
	end
end

-- Подключаем обработчик нажатия клавиш
player:GetMouse().KeyDown:Connect(onKeyDown)