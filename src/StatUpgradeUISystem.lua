-- StatUpgradeUISystem.lua
-- Simple UI for upgrading basic stats using currency
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("StatUpgradeUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local StatUpgradeUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    statSystem = nil,
    statListFrame = nil,
    visible = false,
    window = nil,
}

local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if StatUpgradeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if StatUpgradeUISystem.gui and (not StatUpgradeUISystem.useRobloxObjects or StatUpgradeUISystem.gui.Parent) then
        return StatUpgradeUISystem.gui
    end
    local pgui
    if StatUpgradeUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("StatUpgradeUI")
            if existing then
                StatUpgradeUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "StatUpgradeUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    StatUpgradeUISystem.gui = gui
    if StatUpgradeUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function StatUpgradeUISystem:start(statSys, parentGui)
    self.statSystem = statSys or self.statSystem or StatUpgradeSystem
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    if not self.window then
        self.window = GuiUtil.createWindow("StatUpgradeWindow")
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
        GuiUtil.makeFullScreen(self.window)
    end
    if not self.statListFrame then
        self.statListFrame = createInstance("Frame")
        self.statListFrame.Name = "StatList"
        GuiUtil.applyResponsive(self.statListFrame, 1, 150, 100, 400, 300)
        local layout = createInstance("UIListLayout")
        layout.Name = "ListLayout"
        if Enum and Enum.FillDirection then
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
        end
        if UDim and type(UDim.new) == "function" then
            layout.Padding = UDim.new(0, 5)
        end
        parent(layout, self.statListFrame)
    end
    if self.statListFrame.Parent ~= self.window then
        parent(self.statListFrame, self.window)
    end
    self.gui = parentTarget
    self:update()
    self:setVisible(self.visible)
    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("StatUpdate", function(stat, level)
            local s = self.statSystem and self.statSystem.stats[stat]
            if s then
                s.level = level
                self:update()
            end
        end)
    end
end

local function clearChildren(container)
    if typeof and typeof(container) == "Instance" and container.GetChildren then
        for _, child in ipairs(container:GetChildren()) do
            if child.Destroy then
                child:Destroy()
            end
        end
    elseif type(container) == "table" then
        container.children = {}
    end
end

local function renderStats(container, sys)
    clearChildren(container)
    local layout = container:FindFirstChild("ListLayout")
    if not layout then
        layout = createInstance("UIListLayout")
        layout.Name = "ListLayout"
        if Enum and Enum.FillDirection then
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
        end
        if UDim and type(UDim.new) == "function" then
            layout.Padding = UDim.new(0, 5)
        end
        parent(layout, container)
    end
    for name, stat in pairs(sys.stats) do
        local frame = createInstance("Frame")
        frame.Name = name .. "Frame"
        if UDim2 and type(UDim2.new)=="function" then
            frame.Size = UDim2.new(1, -10, 0, 30)
        end
        GuiUtil.applyResponsive(frame, 6, 200, 30, 800, 40)
        parent(frame, container)

        local label = createInstance("TextLabel")
        local cost = sys.getUpgradeCost and sys:getUpgradeCost(name, 1) or 1
        label.Text = string.format("%s Lv.%d - %dG", name, stat.level, cost)
        if UDim2 and type(UDim2.new)=="function" then
            label.Position = UDim2.new(0, 5, 0, 5)
            label.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = string.format("Buy (%dG)", cost)
        if btn.SetAttribute then
            btn:SetAttribute("StatName", name)
        elseif type(btn) == "table" then
            btn.StatName = name
        end
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(1, -65, 0, 5)
            btn.Size = UDim2.new(0, 60, 0, 20)
        end
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            StatUpgradeUISystem:upgrade(name)
        end)

        if type(frame) == "table" then
            frame.Label = label
            frame.Button = btn
        end
    end
end

function StatUpgradeUISystem:update()
    local sys = self.statSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end
    local container
    if self.statListFrame then
        container = self.statListFrame
    elseif (self.window or gui).FindFirstChild then
        container = (self.window or gui):FindFirstChild("StatList")
    end
    if not container then
        container = createInstance("Frame")
        container.Name = "StatList"
        GuiUtil.applyResponsive(container, 1, 150, 100, 400, 300)
        local layout = createInstance("UIListLayout")
        layout.Name = "ListLayout"
        if Enum and Enum.FillDirection then
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
        end
        if UDim and type(UDim.new) == "function" then
            layout.Padding = UDim.new(0, 5)
        end
        parent(layout, container)
    end
    parent(container, self.window or gui)
    self.statListFrame = container

    renderStats(container, sys)
end

function StatUpgradeUISystem:upgrade(name)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("StatUpgradeRequest", name)
        return true
    end
    return false
end

function StatUpgradeUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function StatUpgradeUISystem:toggle()
    if not self.gui then
        self:start(self.statSystem)
    end
    self:setVisible(not self.visible)
end

return StatUpgradeUISystem

