-- GachaUISystem.lua
-- Provides a simple interface to roll gacha rewards via buttons

local GachaUI = {
    useRobloxObjects = false,
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
    if not child or not parentObj then return end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if GachaUI.gui then return GachaUI.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "GachaUI"
    GachaUI.gui = gui
    if GachaUI.useRobloxObjects then
        local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

local function connect(btn, callback)
    if not btn then return end
    if btn.MouseButton1Click then
        btn.MouseButton1Click:Connect(callback)
    else
        btn.onClick = callback
    end
end

function GachaUI:start(manager)
    self.gameManager = manager or self.gameManager or require(script.Parent:WaitForChild("GameManager"))
    local gui = ensureGui()
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

    -- use a plain window frame; banner images were removed
    self.window = GuiUtil.createWindow("GachaWindow")
    parent(self.window, gui)

    self.resultLabel = createInstance("TextLabel")
    parent(self.resultLabel, self.window)

    self.skillButton = createInstance("TextButton")
    self.skillButton.Text = "Roll Skill"
    parent(self.skillButton, self.window)

    self.companionButton = createInstance("TextButton")
    self.companionButton.Text = "Roll Companion"
    parent(self.companionButton, self.window)

    self.equipmentButton = createInstance("TextButton")
    self.equipmentButton.Text = "Roll Weapon"
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
    local useEnabled = false
    if typeof and typeof(parentGui) == "Instance" then
        local ok, result = pcall(function()
            return parentGui:IsA("ScreenGui")
        end)
        useEnabled = ok and result
    else
        useEnabled = parentGui.Enabled ~= nil
    end
    if useEnabled then
        pcall(function()
            parentGui.Enabled = self.visible
        end)
    else
        parentGui.Visible = self.visible
    end
end

function GachaUI:toggle()
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

