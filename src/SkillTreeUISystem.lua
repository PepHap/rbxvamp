-- SkillTreeUISystem.lua
-- UI for selecting skill branches and upgrading within them
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("SkillTreeUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local SkillTreeUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    treeSystem = nil,
    listFrame = nil,
    window = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if SkillTreeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if SkillTreeUISystem.gui and (not SkillTreeUISystem.useRobloxObjects or SkillTreeUISystem.gui.Parent) then
        return SkillTreeUISystem.gui
    end
    local pgui
    if SkillTreeUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("SkillTreeUI")
            if existing then
                SkillTreeUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "SkillTreeUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    SkillTreeUISystem.gui = gui
    if SkillTreeUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function SkillTreeUISystem:start(treeSys)
    self.treeSystem = treeSys or self.treeSystem
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        self:update()
        return
    end
    self.window = GuiUtil.createWindow("SkillTreeWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.AnchorPoint = Vector2.new(0, 0)
        self.window.Position = UDim2.new(0, 0, 0, 0)
        self.window.Size = UDim2.new(1, 0, 1, 0)
    end
    parent(self.window, gui)
    self:update()
end

local function clearChildren(container)
    if typeof and typeof(container) == "Instance" and container.GetChildren then
        for _, child in ipairs(container:GetChildren()) do
            if child.Destroy then child:Destroy() end
        end
    elseif type(container) == "table" then
        container.children = {}
    end
end

local function renderBranches(frame, index, skill, treeSys)
    clearChildren(frame)
    local cfg = treeSys and treeSys.config and treeSys.config[skill.name]
    if not cfg then return end
    for _, branch in ipairs(cfg) do
        local btn = createInstance("TextButton")
        btn.Text = branch.name
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            treeSys:chooseBranch(index, branch.id)
            SkillTreeUISystem:update()
        end)
    end
end

local function renderSkill(container, index, skill, treeSys)
    local frame = createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        frame.Size = UDim2.new(1, -10, 0, 40)
    end
    GuiUtil.applyResponsive(frame, 6, 200, 40, 800, 60)
    parent(frame, container)
    local label = createInstance("TextLabel")
    label.Text = string.format("%s Lv.%d", skill.name, skill.level)
    if UDim2 and type(UDim2.new)=="function" then
        label.Position = UDim2.new(0, 5, 0, 5)
        label.Size = UDim2.new(1, -70, 0, 20)
    end
    parent(label, frame)

    if not skill.branch then
        renderBranches(frame, index, skill, treeSys)
    else
        local branchLabel = createInstance("TextLabel")
        branchLabel.Text = "Branch: " .. skill.branch
        if UDim2 and type(UDim2.new)=="function" then
            branchLabel.Position = UDim2.new(0, 5, 0, 5)
            branchLabel.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(branchLabel, frame)
        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(1, -65, 0, 5)
            btn.Size = UDim2.new(0, 60, 0, 20)
        end
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            treeSys:upgradeSkill(index, 1)
            SkillTreeUISystem:update()
        end)
    end
end

function SkillTreeUISystem:update()
    local gui = ensureGui()
    local parentGui = self.window or gui
    local container = self.listFrame
    if not container then
        container = createInstance("Frame")
        container.Name = "SkillTreeList"
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
        parent(container, parentGui)
        self.listFrame = container
    end
    clearChildren(container)
    if not self.treeSystem or not self.treeSystem.skillSystem then return end
    for i, skill in ipairs(self.treeSystem.skillSystem.skills) do
        renderSkill(container, i, skill, self.treeSystem)
    end
end

return SkillTreeUISystem
