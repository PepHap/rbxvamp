-- HudSystem.lua
-- Displays player level, experience and currency in a simple GUI

local HudSystem = {
    useRobloxObjects = false,
    gui = nil,
    levelLabel = nil,
    currencyLabel = nil,
    autoButton = nil,
    attackButton = nil,
}

local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))

local function createInstance(className)
    if HudSystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if HudSystem.gui then
        return HudSystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "HudUI"
    HudSystem.gui = gui
    if HudSystem.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

function HudSystem:start()
    local gui = ensureGui()
    self.levelLabel = createInstance("TextLabel")
    self.currencyLabel = createInstance("TextLabel")
    self.autoButton = createInstance("TextButton")
    self.attackButton = createInstance("TextButton")
    self.autoButton.Text = "Auto: OFF"
    self.attackButton.Text = "Attack"
    if self.autoButton.MouseButton1Click then
        self.autoButton.MouseButton1Click:Connect(function()
            HudSystem:toggleAutoBattle()
        end)
    else
        self.autoButton.onClick = function()
            HudSystem:toggleAutoBattle()
        end
    end
    if self.attackButton.MouseButton1Click then
        self.attackButton.MouseButton1Click:Connect(function()
            HudSystem:manualAttack()
        end)
    else
        self.attackButton.onClick = function()
            HudSystem:manualAttack()
        end
    end
    parent(self.levelLabel, gui)
    parent(self.currencyLabel, gui)
    parent(self.autoButton, gui)
    parent(self.attackButton, gui)
    self:update()
end

function HudSystem:update()
    local gui = ensureGui()
    self.levelLabel = self.levelLabel or createInstance("TextLabel")
    parent(self.levelLabel, gui)
    local lvl = PlayerLevelSystem.level or 1
    local exp = PlayerLevelSystem.exp or 0
    local nextExp = PlayerLevelSystem.nextExp or 0
    self.levelLabel.Text = string.format("Lv.%d %d/%d EXP", lvl, exp, nextExp)

    self.currencyLabel = self.currencyLabel or createInstance("TextLabel")
    parent(self.currencyLabel, gui)
    local loc = LocationSystem:getCurrent()
    local currencyType = loc and loc.currency or "gold"
    local amount = CurrencySystem:get(currencyType)
    self.currencyLabel.Text = string.format("%s: %d", currencyType, amount)

    self.autoButton = self.autoButton or createInstance("TextButton")
    parent(self.autoButton, gui)
    local state = AutoBattleSystem.enabled and "ON" or "OFF"
    self.autoButton.Text = "Auto: " .. state

    self.attackButton = self.attackButton or createInstance("TextButton")
    parent(self.attackButton, gui)
    self.attackButton.Text = "Attack"
    if AutoBattleSystem.enabled then
        self.attackButton.Active = false
    else
        self.attackButton.Active = true
    end

    if UDim2 and UDim2.new then
        self.levelLabel.Position = UDim2.new(0, 10, 0, 10)
        self.currencyLabel.Position = UDim2.new(0, 10, 0, 30)
        self.autoButton.Position = UDim2.new(0, 10, 1, -80)
        self.attackButton.Position = UDim2.new(0, 10, 1, -40)
    end
end

function HudSystem:toggleAutoBattle()
    if AutoBattleSystem.enabled then
        AutoBattleSystem:disable()
    else
        AutoBattleSystem:enable()
    end
    self:update()
end

function HudSystem:manualAttack()
    if AutoBattleSystem.enabled then
        return
    end
    local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
    PlayerInputSystem:manualAttack()
end

return HudSystem
