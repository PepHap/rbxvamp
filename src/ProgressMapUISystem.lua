-- ProgressMapUISystem.lua
-- Simple UI displaying progress through locations and stages.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local ProgressMapUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    label = nil,
    progressSystem = nil,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if ProgressMapUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if ProgressMapUI.gui then return ProgressMapUI.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "ProgressMapUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    ProgressMapUI.gui = gui
    if ProgressMapUI.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then gui.Parent = pgui end
    end
    return gui
end

function ProgressMapUI:start(ps)
    self.progressSystem = ps or self.progressSystem or require(script.Parent:WaitForChild("ProgressMapSystem"))
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        self:update()
        self:setVisible(self.visible)
        return
    end
    self.window = GuiUtil.createWindow("ProgressMapWindow")
    parent(self.window, gui)
    self.label = createInstance("TextLabel")
    parent(self.label, self.window)
    self:update()
    self:setVisible(self.visible)
end

function ProgressMapUI:update()
    local ps = self.progressSystem
    if not ps then return end
    local gui = ensureGui()
    self.label = self.label or createInstance("TextLabel")
    parent(self.label, self.window or gui)
    local pr = ps:getProgress()
    self.label.Text = string.format("Location %d - Stage %d", pr.location, pr.stage)
end

function ProgressMapUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function ProgressMapUI:toggle()
    if not self.gui then
        self:start(self.progressSystem)
    end
    self:setVisible(not self.visible)
end

return ProgressMapUI
