local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local QuestUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    questSystem = nil,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if QuestUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
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
    if QuestUISystem.gui then
        return QuestUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "QuestUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    QuestUISystem.gui = gui
    if QuestUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function QuestUISystem:start(questSys)
    self.questSystem = questSys or self.questSystem or require(script.Parent:WaitForChild("QuestSystem"))
    self:update()
    self:setVisible(self.visible)
end

function QuestUISystem:update()
    local qs = self.questSystem
    if not qs then
        return
    end
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = {}
    end
    local container = gui

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
    GuiUtil.setVisible(gui, self.visible)
end

function QuestUISystem:toggle()
    if not self.gui or not self.window then
        self:start(self.questSystem)
    end
    self:setVisible(not self.visible)
end

return QuestUISystem

