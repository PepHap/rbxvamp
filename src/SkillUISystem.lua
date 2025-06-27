-- SkillUISystem.lua
-- Displays owned skills and allows upgrading them with ether.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("SkillUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local SkillUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    skillSystem = nil,
    skillListFrame = nil,
    window = nil,
}

local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if SkillUISystem.useRobloxObjects and typeof ~= nil and Instance and type(Instance.new) == "function" then
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

local function ensureGui(parent)
    if SkillUISystem.gui and (not SkillUISystem.useRobloxObjects or SkillUISystem.gui.Parent) then
        return SkillUISystem.gui
    end
    if parent then
        SkillUISystem.gui = parent
        return parent
    end
    local pgui
    if SkillUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("SkillUI")
            if existing then
                SkillUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "SkillUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    GuiUtil.makeFullScreen(gui)
    SkillUISystem.gui = gui
    if SkillUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function SkillUISystem:start(skillSys, parentGui)
    self.skillSystem = skillSys or self.skillSystem or SkillSystem.new()
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    if not self.window then
        local closeBtn
        self.window, closeBtn = GuiUtil.createWindow("SkillWindow")
        if closeBtn then
            GuiUtil.connectButton(closeBtn, function()
                SkillUISystem:toggle()
            end)
        end
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
        if UDim2 and type(UDim2.new)=="function" then
            self.window.AnchorPoint = Vector2.new(0, 0)
            self.window.Position = UDim2.new(0, 0, 0, 0)
            self.window.Size = UDim2.new(1, 0, 1, 0)
            GuiUtil.clampToScreen(self.window)
        end
    end
    self.gui = parentTarget
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

local function renderSkills(container, sys)
    clearChildren(container)
    local layout = container:FindFirstChild("ListLayout")
    if not layout then
        layout = createInstance("UIListLayout")
        layout.Name = "ListLayout"
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
            layout.Padding = UDim.new(0, 5)
        end
        parent(layout, container)
    end
    if #sys.skills == 0 then
        local none = createInstance("TextLabel")
        none.Text = "No skills available"
        parent(none, container)
        return
    end
    for i, skill in ipairs(sys.skills) do
        local frame = createInstance("Frame")
        frame.Name = skill.name .. "Frame"
        if UDim2 and type(UDim2.new)=="function" then
            frame.Size = UDim2.new(1, -10, 0, 30)
        end
        GuiUtil.applyResponsive(frame, 6, 200, 30, 800, 40)
        GuiUtil.addCrossDecor(frame)
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", skill.name, skill.level)
        if UDim2 and type(UDim2.new)=="function" then
            label.Position = UDim2.new(0, 5, 0, 5)
            label.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        if btn.SetAttribute then
            btn:SetAttribute("Index", i)
        elseif type(btn) == "table" then
            btn.Index = i
        end
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(1, -65, 0, 5)
            btn.Size = UDim2.new(0, 60, 0, 20)
        end
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            SkillUISystem:upgrade(i)
        end)

        if type(frame) == "table" then
            frame.Label = label
            frame.Button = btn
        end
    end
end

function SkillUISystem:update()
    local sys = self.skillSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end
    local parentGui = self.window or gui
    local container
    if self.skillListFrame then
        container = self.skillListFrame
    elseif parentGui.FindFirstChild then
        container = parentGui:FindFirstChild("SkillList")
    end
    if not container then
        container = createInstance("Frame")
        container.Name = "SkillList"
        GuiUtil.applyResponsive(container, 1, 150, 100, 400, 300)
        local layout = createInstance("UIListLayout")
        layout.Name = "ListLayout"
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
            layout.Padding = UDim.new(0, 5)
        end
        parent(layout, container)
    end
    parent(container, parentGui)
    self.skillListFrame = container

    renderSkills(container, sys)
end

function SkillUISystem:upgrade(index)
    if not self.skillSystem then
        return false
    end
    local ok = self.skillSystem:upgradeSkill(index, 1)
    if ok then
        self:update()
    end
    return ok
end

function SkillUISystem:setVisible(on)
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
    GuiUtil.makeFullScreen(parentGui)
    GuiUtil.clampToScreen(parentGui)
end

function SkillUISystem:toggle()
    if not self.gui and type(self.start) == "function" then
        self:start(self.skillSystem)
    end
    self:setVisible(not self.visible)
end

return SkillUISystem
