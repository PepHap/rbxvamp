-- GachaUISystem.lua
-- Provides a simple interface to roll gacha rewards via buttons

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local GachaUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    gameManager = nil,
    resultLabel = nil,
    skillButton = nil,
    companionButton = nil,
    equipmentButton = nil,
    window = nil,
}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if GachaUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "TextButton" then Theme.styleButton(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if GachaUI.gui and (not GachaUI.useRobloxObjects or GachaUI.gui.Parent) then
        return GachaUI.gui
    end
    local pgui
    if GachaUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("GachaUI")
            if existing then
                GachaUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "GachaUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    GachaUI.gui = gui
    if GachaUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

local function connect(btn, callback)
    if not btn then return end
    GuiUtil.connectButton(btn, callback)
end

function GachaUI:start(manager)
    self.gameManager = manager or self.gameManager or require(script.Parent:WaitForChild("GameManager"))
    if self.window then
        return
    end
    local gui = ensureGui()

    -- use a plain window frame; banner images were removed
    self.window = GuiUtil.createWindow("GachaWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.Size = UDim2.new(0, 300, 0, 170)
        self.window.Position = UDim2.new(0.5, -150, 0.5, -85)
    end
    parent(self.window, gui)

    self.resultLabel = createInstance("TextLabel")
    self.resultLabel.Text = "Roll result"
    if UDim2 and type(UDim2.new)=="function" then
        self.resultLabel.Position = UDim2.new(0, 5, 0, 5)
        self.resultLabel.Size = UDim2.new(1, -10, 0, 25)
    end
    parent(self.resultLabel, self.window)

    self.skillButton = createInstance("TextButton")
    self.skillButton.Text = "Roll Skill"
    if UDim2 and type(UDim2.new)=="function" then
        self.skillButton.Position = UDim2.new(0, 5, 0, 35)
        self.skillButton.Size = UDim2.new(1, -10, 0, 30)
    end
    parent(self.skillButton, self.window)

    self.companionButton = createInstance("TextButton")
    self.companionButton.Text = "Roll Companion"
    if UDim2 and type(UDim2.new)=="function" then
        self.companionButton.Position = UDim2.new(0, 5, 0, 70)
        self.companionButton.Size = UDim2.new(1, -10, 0, 30)
    end
    parent(self.companionButton, self.window)

    self.equipmentButton = createInstance("TextButton")
    self.equipmentButton.Text = "Roll Weapon"
    if UDim2 and type(UDim2.new)=="function" then
        self.equipmentButton.Position = UDim2.new(0, 5, 0, 105)
        self.equipmentButton.Size = UDim2.new(1, -10, 0, 30)
    end
    parent(self.equipmentButton, self.window)

    connect(self.skillButton, function() GachaUI:rollSkill() end)
    connect(self.companionButton, function() GachaUI:rollCompanion() end)
    connect(self.equipmentButton, function() GachaUI:rollEquipment("Weapon") end)

    self:setVisible(self.visible)
end

function GachaUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function GachaUI:toggle()
    if not self.gui then
        self:start(self.gameManager)
    end
    self:setVisible(not self.visible)
end

function GachaUI:showResult(result)
    self.resultLabel = self.resultLabel or createInstance("TextLabel")
    parent(self.resultLabel, self.window or ensureGui())
    if not result then
        self.resultLabel.Text = "No reward"
        return
    end
    local rarity = result.rarity or "?"
    self.resultLabel.Text = string.format("%s [%s]", result.name, rarity)
    if Theme and Theme.rarityColors and Theme.rarityColors[rarity] then
        self.resultLabel.TextColor3 = Theme.rarityColors[rarity]
    end
end

function GachaUI:rollSkill()
    if not self.gameManager then return nil end
    local reward = self.gameManager:rollSkill()
    self:showResult(reward)
    return reward
end

function GachaUI:rollCompanion()
    if not self.gameManager then return nil end
    local reward = self.gameManager:rollCompanion()
    self:showResult(reward)
    return reward
end

function GachaUI:rollEquipment(slot)
    if not self.gameManager then return nil end
    local reward = self.gameManager:rollEquipment(slot)
    self:showResult(reward)
    return reward
end

return GachaUI

