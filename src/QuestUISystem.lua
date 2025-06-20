local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local QuestUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    questSystem = nil,
    visible = false,
    window = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if QuestUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if QuestUISystem.gui and (not QuestUISystem.useRobloxObjects or QuestUISystem.gui.Parent) then
        return QuestUISystem.gui
    end
    local pgui
    if QuestUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("QuestUI")
            if existing then
                QuestUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "QuestUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    QuestUISystem.gui = gui
    if QuestUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function QuestUISystem:start(questSys, parentGui)
    self.questSystem = questSys or self.questSystem or require(script.Parent:WaitForChild("QuestSystem"))
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    if not self.window then
        self.window = GuiUtil.createWindow("QuestWindow")
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
    end
    self.gui = parentTarget
    self:update()
    self:setVisible(self.visible)
end

function QuestUISystem:update()
    local qs = self.questSystem
    if not qs then
        return
    end
    local gui = ensureGui()
    local container = self.window or gui
    if type(container) == "table" then
        container.children = {}
    elseif container.ClearAllChildren then
        container:ClearAllChildren()
    end

    for id, q in pairs(qs.quests) do
        local frame = createInstance("Frame")
        frame.Name = id .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Name = "ProgressLabel"
        label.Text = string.format("%s: %d/%d", id, q.progress, q.goal)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Name = "ClaimButton"
        btn.Text = "Claim"
        parent(btn, frame)

        if q.completed and not q.rewarded then
            GuiUtil.connectButton(btn, function()
                QuestUISystem:claim(id)
            end)
        else
            btn.Active = false
        end

        if type(frame) == "table" then
            frame.ProgressLabel = label
            frame.ClaimButton = btn
        end
    end
end

function QuestUISystem:claim(id)
    if not self.questSystem then
        return false
    end
    local ok = self.questSystem:claimReward(id)
    if ok then
        self:update()
    end
    return ok
end

function QuestUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function QuestUISystem:toggle()
    if not self.gui then
        self:start(self.questSystem)
    end
    self:setVisible(not self.visible)
end

return QuestUISystem

