local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local QuestUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    questSystem = nil,
    visible = false,
    window = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

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
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("QuestRequest")
    end
    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("QuestUpdate", function(id, progress, goal, completed, rewarded)
            local q = self.questSystem and self.questSystem.quests[id]
            if q then
                q.progress = progress or q.progress
                q.goal = goal or q.goal
                q.completed = completed or q.completed
                q.rewarded = rewarded or q.rewarded
                self:update()
            end
        end)
        NetworkSystem:onClientEvent("QuestData", function(data)
            if type(data) == "table" and self.questSystem then
                self.questSystem:loadData(data)
                self:update()
            end
        end)
    end
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

    local layout = container:FindFirstChild("QuestLayout")
    if not layout then
        layout = createInstance("UIListLayout")
        layout.Name = "QuestLayout"
        if UDim2 and type(UDim2.new)=="function" then
            layout.Padding = UDim2.new(0,5,0,5)
        end
        parent(layout, container)
    end

    for id, q in pairs(qs.quests) do
        local frame = createInstance("Frame")
        frame.Name = id .. "Frame"
        if UDim2 and type(UDim2.new)=="function" then
            frame.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(frame, container)
        GuiUtil.applyResponsive(frame, 6, 200, 30, 800, 40)
        GuiUtil.addCrossDecor(frame)

        local label = createInstance("TextLabel")
        label.Name = "ProgressLabel"
        label.Text = string.format("%s: %d/%d", id, q.progress, q.goal)
        if UDim2 and type(UDim2.new)=="function" then
            label.Position = UDim2.new(0, 5, 0, 5)
            label.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Name = "ClaimButton"
        btn.Text = "Claim"
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(1, -65, 0, 5)
            btn.Size = UDim2.new(0, 60, 0, 20)
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

