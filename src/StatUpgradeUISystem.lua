-- StatUpgradeUISystem.lua
-- Simple UI for upgrading basic stats using currency

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local StatUpgradeUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    statSystem = nil,
    statListFrame = nil,
    visible = false,
}

local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if StatUpgradeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if not child or not parentObj then
        return
    end
    if typeof and typeof(child) == "Instance" then
        if typeof(parentObj) == "Instance" then
            child.Parent = parentObj
        end
    else
        child.Parent = parentObj
    end
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if StatUpgradeUISystem.gui then
        return StatUpgradeUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "StatUpgradeUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    StatUpgradeUISystem.gui = gui
    if StatUpgradeUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function StatUpgradeUISystem:start(statSys)
    self.statSystem = statSys or self.statSystem or StatUpgradeSystem
    local gui = ensureGui()
    if self.statListFrame then
        if self.statListFrame.Parent ~= gui then
            parent(self.statListFrame, gui)
            self.gui = gui
        end
        self:update()
        self:setVisible(self.visible)
        return
    end
    self:update()
    self:setVisible(self.visible)
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
    for name, stat in pairs(sys.stats) do
        local frame = createInstance("Frame")
        frame.Name = name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", name, stat.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        if btn.SetAttribute then
            btn:SetAttribute("StatName", name)
        elseif type(btn) == "table" then
            btn.StatName = name
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
    elseif gui.FindFirstChild then
        container = gui:FindFirstChild("StatList")
    end
    if not container then
        container = createInstance("Frame")
        container.Name = "StatList"
    end
    parent(container, gui)
    self.statListFrame = container

    renderStats(container, sys)
end

function StatUpgradeUISystem:upgrade(name)
    if not self.statSystem then
        return false
    end
    local ok = self.statSystem:upgradeStat(name, 1, "gold")
    if ok then
        self:update()
    end
    return ok
end

function StatUpgradeUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    GuiUtil.setVisible(gui, self.visible)
end

function StatUpgradeUISystem:toggle()
    if not self.gui then
        self:start(self.statSystem)
    end
    self:setVisible(not self.visible)
end

return StatUpgradeUISystem

