-- ScoreboardUISystem.lua
-- Displays the top stage scores sent by ScoreboardSystem.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ScoreboardUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local ScoreboardUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    label = nil,
    visible = false,
}

local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if ScoreboardUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then inst.IgnoreGuiInset = true end
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function parent(child, p)
    GuiUtil.parent(child, p)
end

local function ensureGui()
    if ScoreboardUI.gui and (not ScoreboardUI.useRobloxObjects or ScoreboardUI.gui.Parent) then
        return ScoreboardUI.gui
    end
    local pgui
    if ScoreboardUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("ScoreboardUI")
            if existing then
                ScoreboardUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "ScoreboardUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then gui.Enabled = true end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    ScoreboardUI.gui = gui
    if ScoreboardUI.useRobloxObjects and pgui then gui.Parent = pgui end
    return gui
end

function ScoreboardUI:start()
    local gui = ensureGui()
    if not self.window then
        self.window = GuiUtil.createWindow("ScoreboardWindow")
        parent(self.window, gui)
        GuiUtil.makeFullScreen(self.window)
        self.label = createInstance("TextLabel")
        if UDim2 and type(UDim2.new)=="function" then
            self.label.Size = UDim2.new(1, -10, 1, -10)
            self.label.Position = UDim2.new(0, 5, 0, 5)
            self.label.TextXAlignment = Enum and Enum.TextXAlignment.Left or 0
            self.label.TextYAlignment = Enum and Enum.TextYAlignment.Top or 0
        end
        parent(self.label, self.window)
    end
    NetworkSystem:onClientEvent("ScoreboardUpdate", function(data)
        ScoreboardUI:updateBoard(data)
    end)
    self:setVisible(self.visible)
end

function ScoreboardUI:updateBoard(data)
    if not self.label then return end
    if type(data) ~= "table" then
        self.label.Text = "No scores"
        return
    end
    local lines = {}
    for i, entry in ipairs(data) do
        table.insert(lines, string.format("%d. %s - %d", i, entry.name, entry.stage))
    end
    self.label.Text = table.concat(lines, "\n")
end

function ScoreboardUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function ScoreboardUI:toggle()
    if not self.gui then self:start() end
    self:setVisible(not self.visible)
end

return ScoreboardUI
