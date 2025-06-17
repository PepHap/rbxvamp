-- ProgressMapUISystem.lua
-- Simple UI displaying progress through locations and stages.

local ProgressMapUI = {
    useRobloxObjects = false,
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
    if not child or not parentObj then return end
    if typeof and typeof(child)=="Instance" and typeof(parentObj)=="Instance" then
        child.Parent = parentObj
    else
        child.Parent = parentObj
    end
    if type(parentObj)=="table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if ProgressMapUI.gui then return ProgressMapUI.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "ProgressMapUI"
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
    if parentGui.Enabled ~= nil then parentGui.Enabled = self.visible end
end

function ProgressMapUI:toggle()
    self:setVisible(not self.visible)
end

return ProgressMapUI
