-- GachaUISystem.lua
-- Provides a simple interface to roll gacha rewards via buttons
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("GachaUISystem should only be required on the client", 2)
end

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
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if GachaUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then inst.IgnoreGuiInset = true end
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
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
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

function GachaUI:start(manager, parentGui)
    self.gameManager = manager or self.gameManager or require(script.Parent:WaitForChild("ClientGameManager"))
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    local created = false
    if not self.window then
        -- use a plain window frame; banner images were removed
        self.window = GuiUtil.createWindow("GachaWindow")
        if UDim2 and type(UDim2.new)=="function" then
            -- Show the gacha interface across the entire screen for a cleaner
            -- layout on various resolutions.
            self.window.Size = UDim2.new(1, 0, 1, 0)
            self.window.AnchorPoint = Vector2.new(0, 0)
            self.window.Position = UDim2.new(0, 0, 0, 0)
        end
        created = true
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
    end
    self.gui = parentTarget

    if created then
        local closeBtn = createInstance("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Text = "X"
        if UDim2 and type(UDim2.new)=="function" then
            closeBtn.Size = UDim2.new(0,20,0,20)
            closeBtn.Position = UDim2.new(1,-25,0,5)
        end
        parent(closeBtn, self.window)
        connect(closeBtn, function()
            GachaUI:toggle()
        end)

        local layout = createInstance("UIListLayout")
        layout.Name = "ButtonLayout"
        if Enum and Enum.FillDirection then
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            if layout.HorizontalAlignment ~= nil then
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
            if layout.VerticalAlignment ~= nil then
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
            end
        end
        if UDim and type(UDim.new) == "function" then
            layout.Padding = UDim.new(0,5)
        end
        parent(layout, self.window)

        self.resultLabel = createInstance("TextLabel")
        self.resultLabel.Text = "Roll result"
        if UDim2 and type(UDim2.new)=="function" then
            self.resultLabel.Size = UDim2.new(1, -10, 0, 25)
        end
        parent(self.resultLabel, self.window)

        self.skillButton = createInstance("TextButton")
        self.skillButton.Text = "Roll Skill"
        if UDim2 and type(UDim2.new)=="function" then
            self.skillButton.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(self.skillButton, self.window)

        self.companionButton = createInstance("TextButton")
        self.companionButton.Text = "Roll Companion"
        if UDim2 and type(UDim2.new)=="function" then
            self.companionButton.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(self.companionButton, self.window)

        self.equipmentButton = createInstance("TextButton")
        self.equipmentButton.Text = "Roll Weapon"
        if UDim2 and type(UDim2.new)=="function" then
            self.equipmentButton.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(self.equipmentButton, self.window)

        connect(self.skillButton, function()
            NetworkSystem:fireServer("GachaRequest", "skill")
        end)
        connect(self.companionButton, function()
            NetworkSystem:fireServer("GachaRequest", "companion")
        end)
        connect(self.equipmentButton, function()
            NetworkSystem:fireServer("GachaRequest", "equipment", "Weapon")
        end)
    end

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("GachaResult", function(kind, reward)
            if reward then
                GachaUI:showResult(reward)
            else
                GachaUI:showResult(nil)
            end
        end)
    end

    self:setVisible(self.visible)
end

function GachaUI:setVisible(on)
    local newVis = not not on
    if newVis == self.visible then
        local gui = ensureGui()
        local parentGui = self.window or gui
        GuiUtil.setVisible(parentGui, self.visible)
        return
    end

    self.visible = newVis
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
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "skill")
    end
end

function GachaUI:rollCompanion()
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "companion")
    end
end

function GachaUI:rollEquipment(slot)
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "equipment", slot)
    end
end

return GachaUI

