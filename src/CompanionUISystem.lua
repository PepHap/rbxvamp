-- CompanionUISystem.lua
-- Displays owned companions and allows upgrading them with ether.

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local CompanionUISystem = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    visible = false,
    companionSystem = nil,
    listFrame = nil,
    window = nil,
}

local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if CompanionUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if CompanionUISystem.gui and (not CompanionUISystem.useRobloxObjects or CompanionUISystem.gui.Parent) then
        return CompanionUISystem.gui
    end
    local pgui
    if CompanionUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("CompanionUI")
            if existing then
                CompanionUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "CompanionUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    CompanionUISystem.gui = gui
    if CompanionUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function CompanionUISystem:start(compSys, parentGui)
    self.companionSystem = compSys or self.companionSystem or {companions = {}}
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    if not self.window then
        self.window = GuiUtil.createWindow("CompanionWindow")
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
    end
    self.gui = parentTarget
    self:update()
    self:setVisible(self.visible)
end

local function renderCompanions(container, sys)
    if type(container) == "table" then
        container.children = {}
    elseif container.ClearAllChildren then
        container:ClearAllChildren()
    end
    if #sys.companions == 0 then
        local none = createInstance("TextLabel")
        none.Text = "No companions"
        parent(none, container)
        return
    end
    for i, comp in ipairs(sys.companions) do
        local frame = createInstance("Frame")
        frame.Name = comp.name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", comp.name, comp.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        if btn.SetAttribute then
            btn:SetAttribute("Index", i)
        elseif type(btn) == "table" then
            btn.Index = i
        end
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            CompanionUISystem:upgrade(i)
        end)

        if type(frame) == "table" then
            frame.Label = label
            frame.Button = btn
        end
    end
end

function CompanionUISystem:update()
    local sys = self.companionSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end

    local parentGui = self.window or gui
    local container
    if self.listFrame then
        container = self.listFrame
    elseif parentGui.FindFirstChild then
        container = parentGui:FindFirstChild("CompanionList")
    end
    if not container then
        container = createInstance("Frame")
        container.Name = "CompanionList"
    end
    parent(container, parentGui)
    self.listFrame = container

    renderCompanions(container, sys)
end

function CompanionUISystem:upgrade(index)
    if not self.companionSystem then
        return false
    end
    local ok = self.companionSystem:upgradeCompanion(index, 1)
    if ok then
        self:update()
    end
    return ok
end

function CompanionUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function CompanionUISystem:toggle()
    if not self.gui and type(self.start) == "function" then
        self:start(self.companionSystem)
    end
    self:setVisible(not self.visible)
end

return CompanionUISystem
