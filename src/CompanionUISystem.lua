-- CompanionUISystem.lua
-- Displays owned companions and allows upgrading them with ether.

local CompanionUISystem = {
    useRobloxObjects = false,
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
    if CompanionUISystem.gui then
        return CompanionUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "CompanionUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    CompanionUISystem.gui = gui
    if CompanionUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function CompanionUISystem:start(compSys)
    self.companionSystem = compSys or self.companionSystem or {companions = {}}
    local gui = ensureGui()

    -- create a simple window frame; images are optional and removed to keep the repo text only
    self.window = GuiUtil.createWindow("CompanionWindow")
    parent(self.window, gui)

    self:update()
    self:setVisible(self.visible)
end

local function renderCompanions(container, sys)
    if type(container) == "table" then
        container.children = {}
    elseif container.ClearAllChildren then
        container:ClearAllChildren()
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
    self:setVisible(not self.visible)
end

return CompanionUISystem
