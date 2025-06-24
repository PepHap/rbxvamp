-- RaidUISystem.lua
-- Displays basic raid progress updates sent by the server.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("RaidUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local RaidUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    statusLabel = nil,
    visible = false,
    hideDelay = 0,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if RaidUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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

local function parent(child, p)
    GuiUtil.parent(child, p)
end

local function ensureGui()
    if RaidUI.gui and (not RaidUI.useRobloxObjects or RaidUI.gui.Parent) then
        return RaidUI.gui
    end
    local pgui
    if RaidUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("RaidUI")
            if existing then
                RaidUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "RaidUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    RaidUI.gui = gui
    if RaidUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function RaidUI:start()
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
    else
        self.window = GuiUtil.createWindow("RaidWindow")
        parent(self.window, gui)
        GuiUtil.makeFullScreen(self.window)
        self.statusLabel = createInstance("TextLabel")
        parent(self.statusLabel, self.window)
    end
    self:setVisible(self.visible)
    NetworkSystem:onClientEvent("RaidStatus", function(action, a, b)
        RaidUI:onStatus(action, a, b)
    end)
    NetworkSystem:onClientEvent("RaidEvent", function(action, a, b)
        RaidUI:onStatus(action, a, b)
    end)
    NetworkSystem:onClientEvent("RaidReward", function(kind, amount)
        RaidUI:onReward(kind, amount)
    end)
end

function RaidUI:onStatus(action, a, b)
    if not self.statusLabel then
        return
    end
    if action == "start" then
        self.statusLabel.Text = string.format("Raid Started (%d)", a)
        self:setVisible(true)
    elseif action == "lobby" then
        self.statusLabel.Text = "Preparing Raid..."
        self:setVisible(true)
    elseif action == "progress" then
        self.statusLabel.Text = string.format("Raid %d/%d", a, b)
    elseif action == "complete" then
        self.statusLabel.Text = "Raid Complete"
        self.hideDelay = 3
    end
end

function RaidUI:onReward(kind, amount)
    if not self.statusLabel then return end
    self.statusLabel.Text = string.format("Reward: %s %s", tostring(kind), tostring(amount))
    self.hideDelay = 3
    self:setVisible(true)
end

function RaidUI:update(dt)
    dt = dt or 0
    if self.hideDelay and self.hideDelay > 0 then
        self.hideDelay = math.max(0, self.hideDelay - dt)
        if self.hideDelay == 0 then
            self:setVisible(false)
        end
    end
end

function RaidUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function RaidUI:toggle()
    if not self.gui then
        self:start()
    end
    self:setVisible(not self.visible)
end

return RaidUI
