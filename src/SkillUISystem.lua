-- SkillUISystem.lua
-- Displays owned skills and allows upgrading them with ether.

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local SkillUISystem = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    visible = false,
    skillSystem = nil,
    skillListFrame = nil,
    window = nil,
}

local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if SkillUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if SkillUISystem.gui then
        return SkillUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "SkillUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if SkillUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    SkillUISystem.gui = gui
    return gui
end

function SkillUISystem:start(skillSys, parentGui)
    self.skillSystem = skillSys or self.skillSystem or SkillSystem.new()
    local rootGui = ensureGui()
    local container = parentGui or rootGui

    -- window backgrounds were removed; use plain window frame
    self.window = GuiUtil.createWindow("SkillWindow")
    parent(self.window, container)

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
    if #sys.skills == 0 then
        local none = createInstance("TextLabel")
        none.Text = "No skills available"
        parent(none, container)
        return
    end
    for i, skill in ipairs(sys.skills) do
        local frame = createInstance("Frame")
        frame.Name = skill.name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", skill.name, skill.level)
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
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function SkillUISystem:toggle()
    if not self.gui and type(self.start) == "function" then
        self:start(self.skillSystem)
    elseif self.window and self.window.Parent ~= self.gui then
        parent(self.window, self.gui)
    end
    self:setVisible(not self.visible)
end

return SkillUISystem
