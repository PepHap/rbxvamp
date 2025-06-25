local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("QuestUISystem should only be required on the client", 2)
end

local QuestUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    questSystem = nil,
    visible = false,
    window = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local QuestSystem = require(script.Parent:WaitForChild("ClientQuestSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if QuestUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then
            inst.IgnoreGuiInset = true
        end
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "TextButton" then Theme.styleButton(inst)
            elseif className == "Frame" then Theme.styleWindow(inst)
            end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl)
        end
    end
    return tbl
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
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    QuestUISystem.gui = gui
    if QuestUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function QuestUISystem:start(questSys, parentGui)
    self.questSystem = questSys or self.questSystem or QuestSystem
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    if not self.window then
        self.window = GuiUtil.createWindow("QuestWindow")
    end
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
        if UDim2 and type(UDim2.new)=="function" then
            self.window.AnchorPoint = Vector2.new(0, 0)
            self.window.Position = UDim2.new(0, 0, 0, 0)
            self.window.Size = UDim2.new(1, 0, 1, 0)
        end
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

    local layout
    if container.FindFirstChild then
        layout = container:FindFirstChild("QuestLayout")
    elseif type(container) == "table" and container.children then
        for _, child in ipairs(container.children) do
            if child.Name == "QuestLayout" then
                layout = child
                break
            end
        end
    end
    if not layout then
        layout = createInstance("UIListLayout")
        layout.Name = "QuestLayout"
        -- UIListLayout.Padding expects a UDim value per Roblox API
        -- https://create.roblox.com/docs/reference/engine/classes/UIListLayout#Padding
        if UDim and type(UDim.new) == "function" then
            layout.Padding = UDim.new(0, 5)
        end
        if Enum and Enum.HorizontalAlignment then
            if layout.HorizontalAlignment ~= nil then
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
        end
        if Enum and Enum.VerticalAlignment then
            if layout.VerticalAlignment ~= nil then
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
            end
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
end

function QuestUISystem:toggle()
    if not self.gui then
        self:start(self.questSystem)
    end
    self:setVisible(not self.visible)
end

return QuestUISystem

