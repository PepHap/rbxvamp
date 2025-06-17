-- PlayerInputSystem.lua  •  17 июн 2025 patch
-- Слушает клавишу «B» и передаёт команду InventoryUI.

local UIS = game:GetService("UserInputService")

local PlayerInputSystem = {}
PlayerInputSystem.__index = PlayerInputSystem

function PlayerInputSystem.new(invUI)
    local self = setmetatable({
        _inventoryUI = invUI,
    }, PlayerInputSystem)

    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.B and self._inventoryUI then
            self._inventoryUI:toggle()
        end
    end)

    return self
end

return PlayerInputSystem
