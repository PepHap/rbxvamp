-- HudSystem.lua
-- Displays player level, experience and currency in a simple GUI

local HudSystem = {
    useRobloxObjects = false,
    gui = nil,
    levelLabel = nil,
    currencyLabel = nil,
}

local PlayerLevelSystem = require("src.PlayerLevelSystem")
local CurrencySystem = require("src.CurrencySystem")
local LocationSystem = require("src.LocationSystem")

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
    parent(self.levelLabel, gui)
    parent(self.currencyLabel, gui)
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
end

return HudSystem
