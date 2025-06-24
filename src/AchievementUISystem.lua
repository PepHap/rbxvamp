-- AchievementUISystem.lua
-- Displays achievement progress and allows claiming rewards.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("AchievementUISystem should only be required on the client", 2)
end
local AchievementUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    achievementSystem = nil,
    window = nil,
}

local AchievementSystem = require(script.Parent:WaitForChild("AchievementSystem"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if AchievementUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if AchievementUI.gui and (not AchievementUI.useRobloxObjects or AchievementUI.gui.Parent) then
        return AchievementUI.gui
    end
    local pgui
    if AchievementUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("AchievementUI")
            if existing then
                AchievementUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "AchievementUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then gui.Enabled = true end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    AchievementUI.gui = gui
    if AchievementUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function AchievementUI:start(sys)
    self.achievementSystem = sys or self.achievementSystem or AchievementSystem
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
        end
        self:update()
        self:setVisible(self.visible)
        return
    end
    self.window = GuiUtil.createWindow("AchievementWindow")
    parent(self.window, gui)
    GuiUtil.makeFullScreen(self.window)
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

function AchievementUI:update()
    local sys = self.achievementSystem
    if not sys then return end
    local gui = ensureGui()
    local parentGui = self.window or gui
    clearChildren(parentGui)
    local offset = 0
    for i, def in ipairs(sys.definitions) do
        local p = sys.progress[def.id] or {value=0, completed=false, rewarded=false}
        local frame = createInstance("Frame")
        if UDim2 and type(UDim2.new)=="function" then
            frame.Position = UDim2.new(0, 5, 0, offset)
            frame.Size = UDim2.new(1, -10, 0, 30)
        end
        parent(frame, parentGui)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s: %d/%d", def.id, p.value, def.goal)
        if UDim2 and type(UDim2.new)=="function" then
            label.Position = UDim2.new(0, 5, 0, 5)
            label.Size = UDim2.new(1, -70, 0, 20)
        end
        parent(label, frame)

        if p.completed and not p.rewarded then
            local btn = createInstance("TextButton")
            btn.Text = "Claim"
            if UDim2 and type(UDim2.new)=="function" then
                btn.Position = UDim2.new(1, -65, 0, 5)
                btn.Size = UDim2.new(0, 60, 0, 20)
            end
            parent(btn, frame)
            GuiUtil.connectButton(btn, function()
                AchievementUI:claim(def.id)
            end)
        end
        offset = offset + 35
    end
end

function AchievementUI:claim(id)
    if not self.achievementSystem then return false end
    local ok = self.achievementSystem:claim(id)
    if ok then
        self:update()
    end
    return ok
end

function AchievementUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function AchievementUI:toggle()
    if not self.gui then
        self:start(self.achievementSystem)
    end
    self:setVisible(not self.visible)
end

return AchievementUI
