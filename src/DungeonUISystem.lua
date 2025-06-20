-- DungeonUISystem.lua
-- Simple interface for starting optional dungeons using keys

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local DungeonUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    dungeonSystem = nil,
    window = nil,
    listFrame = nil,
    progressLabel = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local DungeonSystem = require(script.Parent:WaitForChild("DungeonSystem"))
local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if DungeonUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if DungeonUI.gui and (not DungeonUI.useRobloxObjects or DungeonUI.gui.Parent) then
        return DungeonUI.gui
    end
    local pgui
    if DungeonUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("DungeonUI")
            if existing then
                DungeonUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "DungeonUI"
    if gui.Enabled ~= nil then gui.Enabled = true end
    DungeonUI.gui = gui
    if DungeonUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function DungeonUI:start(dungeonSys)
    self.dungeonSystem = dungeonSys or self.dungeonSystem or DungeonSystem
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
        end
        self:update()
        self:setVisible(self.visible)
        return
    end

    self.window = GuiUtil.createWindow("DungeonWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.Size = UDim2.new(0, 300, 0, 200)
        self.window.Position = UDim2.new(0.5, -150, 0.5, -100)
    end
    parent(self.window, gui)
    self.listFrame = createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        self.listFrame.Position = UDim2.new(0, 0, 0, 0)
        self.listFrame.Size = UDim2.new(1, 0, 1, -30)
    end
    parent(self.listFrame, self.window)
    self.progressLabel = createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.progressLabel.Position = UDim2.new(0, 5, 1, -25)
        self.progressLabel.Size = UDim2.new(1, -10, 0, 20)
    end
    parent(self.progressLabel, self.window)

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("DungeonState", function(active, count, req)
            DungeonSystem.active = active
            DungeonSystem.killCount = count or 0
            if active and DungeonSystem.dungeons[active] then
                DungeonSystem.dungeons[active].kills = req or DungeonSystem.dungeons[active].kills
            end
            DungeonUI:update()
        end)
        NetworkSystem:onClientEvent("DungeonProgress", function(count, req, active)
            DungeonSystem.active = active or DungeonSystem.active
            DungeonSystem.killCount = count or 0
            DungeonUI:update()
        end)
    end

    self:update()
    self:setVisible(self.visible)
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

local function renderDungeons(container, sys)
    clearChildren(container)
    for id, info in pairs(sys.dungeons) do
        local frame = createInstance("Frame")
        if UDim2 and type(UDim2.new)=="function" then
            local count = 0
            if type(container) == "table" and container.children then
                count = #container.children
            elseif container.GetChildren then
                count = #container:GetChildren()
            end
            frame.Position = UDim2.new(0, 5, 0, count*35)
            frame.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(frame, container)
        local label = createInstance("TextLabel")
        label.Text = string.format("%s - %d kills for %d %s", id, info.kills, info.reward, info.currency)
        if UDim2 and type(UDim2.new)=="function" then
            label.Position = UDim2.new(0, 5, 0, 5)
            label.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(label, frame)
        local btn = createInstance("TextButton")
        btn.Text = string.format("Start (%d keys)", KeySystem:getCount(info.key))
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(1, -65, 0, 5)
            btn.Size = UDim2.new(0, 60, 0, 20)
        end
        parent(btn, frame)
        GuiUtil.connectButton(btn, function()
            DungeonUI:startDungeon(id)
        end)
        if type(frame) == "table" then
            frame.Label = label
            frame.Button = btn
        end
    end
end

function DungeonUI:update()
    local sys = self.dungeonSystem
    if not sys then return end
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.listFrame = self.listFrame or createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        self.listFrame.Position = UDim2.new(0, 0, 0, 0)
        self.listFrame.Size = UDim2.new(1, 0, 1, -30)
    end
    parent(self.listFrame, parentGui)
    renderDungeons(self.listFrame, sys)

    self.progressLabel = self.progressLabel or createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.progressLabel.Position = UDim2.new(0, 5, 1, -25)
        self.progressLabel.Size = UDim2.new(1, -10, 0, 20)
    end
    parent(self.progressLabel, parentGui)
    if sys.active then
        local info = sys.dungeons[sys.active]
        local kills = sys.killCount or 0
        self.progressLabel.Text = string.format("%s: %d/%d", sys.active, kills, info.kills)
    else
        self.progressLabel.Text = "No dungeon active"
    end
end

function DungeonUI:startDungeon(kind)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("DungeonRequest", kind)
    end
    if not self.dungeonSystem then return false end
    local ok = self.dungeonSystem:start(kind)
    if ok then
        self:update()
    end
    return ok
end

function DungeonUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function DungeonUI:toggle()
    if not self.gui then
        self:start(self.dungeonSystem)
    end
    self:setVisible(not self.visible)
end

return DungeonUI

