local QuestUISystem = {
    useRobloxObjects = false,
    gui = nil,
    questSystem = nil,
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
    local gui = ensureGui()
    self.window = GuiUtil.createWindow("QuestWindow")
    parent(self.window, gui)
    if UDim2 and UDim2.new then
        self.window.Size = UDim2.new(0, 300, 0, 200)
        self.window.Position = UDim2.new(0.5, -150, 0.5, -100)
    end
    self:update()
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
    local parentGui = self.window or gui
    local container = parentGui

    for id, q in pairs(qs.quests) do
        local frame = createInstance("Frame")
        frame.Name = id .. "Frame"
        if UDim2 and UDim2.new then
            frame.Position = UDim2.new(0, 10, 0, 40 + (#container.children or 0)*40)
            frame.Size = UDim2.new(1, -20, 0, 30)
        end
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Name = "ProgressLabel"
        label.Text = string.format("%s: %d/%d", id, q.progress, q.goal)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Name = "ClaimButton"
        btn.Text = "Claim"
        if UDim2 and UDim2.new then
            btn.Position = UDim2.new(1, -80, 0, 0)
            btn.Size = UDim2.new(0, 70, 1, 0)
        end
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

return QuestUISystem

