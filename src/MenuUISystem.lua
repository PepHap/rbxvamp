local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("MenuUISystem should only be required on the client", 2)
end

local MenuUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    tabFrame = nil,
    contentFrame = nil,
    tabs = {},
    tabButtons = {},
    currentTab = 1,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
local SkillUISystem = require(script.Parent:WaitForChild("SkillUISystem"))
local AchievementUISystem = require(script.Parent:WaitForChild("AchievementUISystem"))
local CompanionUISystem = require(script.Parent:WaitForChild("CompanionUISystem"))
local StatUpgradeUISystem = require(script.Parent:WaitForChild("StatUpgradeUISystem"))
local GachaUISystem = require(script.Parent:WaitForChild("GachaUISystem"))
local QuestUISystem = require(script.Parent:WaitForChild("QuestUISystem"))
local DungeonUISystem = require(script.Parent:WaitForChild("DungeonUISystem"))
local CrystalExchangeUISystem = require(script.Parent:WaitForChild("CrystalExchangeUISystem"))
local ProgressMapUISystem = require(script.Parent:WaitForChild("ProgressMapUISystem"))
local LevelUISystem = require(script.Parent:WaitForChild("LevelUISystem"))

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if MenuUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
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
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if MenuUI.gui and (not MenuUI.useRobloxObjects or MenuUI.gui.Parent) then
        return MenuUI.gui
    end
    local pgui
    if MenuUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("MenuUI")
            if existing then
                MenuUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "MenuUI"
    GuiUtil.makeFullScreen(gui)
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    MenuUI.gui = gui
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if MenuUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function MenuUI:addDefaultTabs()
    if #self.tabs > 0 then return end
    self:addTab("Inventory", InventoryUISystem)
    self:addTab("Skills", SkillUISystem)
    self:addTab("Achievements", AchievementUISystem)
    self:addTab("Companions", CompanionUISystem)
    self:addTab("Stats", StatUpgradeUISystem)
    self:addTab("Levels", LevelUISystem)
    self:addTab("Gacha", GachaUISystem)
    self:addTab("Quests", QuestUISystem)
    self:addTab("Dungeons", DungeonUISystem)
    self:addTab("Exchange", CrystalExchangeUISystem)
    self:addTab("Progress", ProgressMapUISystem)
end

---Toggles the menu visibility, showing the specified tab when opening.
--@param name string tab name
function MenuUI:toggleTab(name)
    if not self.gui then
        self:start()
    end
    local idx = self:getTabIndex(name)
    if self.visible and idx and idx == self.currentTab then
        self:setVisible(false)
    else
        self:openTab(name)
    end
end

function MenuUI:addTab(name, system)
    table.insert(self.tabs, {name=name, system=system})
end

function MenuUI:start()
    if self.window then
        local gui = ensureGui()
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        return
    end
    self:addDefaultTabs()
    local gui = ensureGui()
    self.window = GuiUtil.createWindow("MenuWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.AnchorPoint = Vector2.new(0.5, 0.5)
        self.window.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    parent(self.window, gui)


    self.tabFrame = createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        self.tabFrame.Position = UDim2.new(0,0,0,0)
        self.tabFrame.Size = UDim2.new(1,0,0,30)
    end
    parent(self.tabFrame, self.window)

    local layout = createInstance("UIListLayout")
    layout.Name = "TabLayout"
    if Enum and Enum.FillDirection then
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        if layout.HorizontalAlignment ~= nil then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end
        if layout.VerticalAlignment ~= nil then
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
        end
    end
    parent(layout, self.tabFrame)

    self.contentFrame = createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        self.contentFrame.Position = UDim2.new(0, 0, 0, 30)
        self.contentFrame.Size = UDim2.new(1, 0, 1, -30)
    end
    parent(self.contentFrame, self.window)

    for i,tab in ipairs(self.tabs) do
        local btn = createInstance("TextButton")
        btn.Text = tab.name
        if UDim2 and type(UDim2.new)=="function" then
            btn.Size = UDim2.new(0, 100, 0, 30)
        end
        btn.LayoutOrder = i
        parent(btn, self.tabFrame)
        self.tabButtons[i] = btn
        GuiUtil.connectButton(btn, function()
            MenuUI:showTab(i)
        end)
        if tab.system == LevelUISystem then
            tab.system:start()
        else
            tab.system:start(nil, self.contentFrame)
        end
        tab.system:setVisible(false)
    end
    self:setVisible(self.visible)
    if #self.tabs > 0 then
        self:showTab(self.currentTab)
    end
end

function MenuUI:showTab(index)
    self.currentTab = index
    for i,tab in ipairs(self.tabs) do
        if tab.system and tab.system.setVisible then
            tab.system:setVisible(i==index)
        end
    end
end

---Finds a tab index by its name.
-- @param name string tab name
-- @return number? index or nil
function MenuUI:getTabIndex(name)
    for i, tab in ipairs(self.tabs) do
        if tab.name == name then
            return i
        end
    end
    return nil
end

---Shows the specified tab by name and ensures the menu is visible.
-- @param name string tab name
function MenuUI:openTab(name)
    if not self.gui then
        self:start()
    end
    local idx = self:getTabIndex(name)
    if idx then
        self:showTab(idx)
    end
    self:setVisible(true)
end

function MenuUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
    if not self.visible then
        for _, tab in ipairs(self.tabs) do
            if tab.system and tab.system.setVisible then
                tab.system:setVisible(false)
            end
        end
    else
        self:showTab(self.currentTab)
    end
end

function MenuUI:toggle()
    if not self.gui then
        self:start()
    end
    self:setVisible(not self.visible)
end

return MenuUI
