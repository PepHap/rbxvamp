-- SkillTreeUISystem.lua
-- UI for selecting skill branches and upgrading within them

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
    if SkillTreeUISystem.gui then return SkillTreeUISystem.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "SkillTreeUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    SkillTreeUISystem.gui = gui
    if SkillTreeUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
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
    parent(frame, container)
    local label = createInstance("TextLabel")
    label.Text = string.format("%s Lv.%d", skill.name, skill.level)
    parent(label, frame)

    if not skill.branch then
        renderBranches(frame, index, skill, treeSys)
    else
        local branchLabel = createInstance("TextLabel")
        branchLabel.Text = "Branch: " .. skill.branch
        parent(branchLabel, frame)
        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
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
