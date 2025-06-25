-- LevelUISystem.lua
-- Displays the current player level and stage progress in a small window
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("LevelUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local LevelSystem = require(script.Parent:WaitForChild("ClientLevelSystem"))
local LocalizationSystem = require(script.Parent:WaitForChild("LocalizationSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local LevelUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    levelLabel = nil,
    stageLabel = nil,
    visible = false,
}

local function createInstance(className)
    if LevelUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then
            inst.IgnoreGuiInset = true
        end
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
    if LevelUI.gui and (not LevelUI.useRobloxObjects or LevelUI.gui.Parent) then
        return LevelUI.gui
    end
    local pgui
    if LevelUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("LevelUI")
            if existing then
                LevelUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "LevelUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    LevelUI.gui = gui
    if LevelUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function LevelUI:start(pls, lvlSys, parentGui)
    -- Support older call signatures where ``lvlSys`` was actually the parent
    -- frame passed from ``MenuUISystem:start``
    if parentGui == nil and self.useRobloxObjects then
        if typeof(lvlSys) == "Instance" and lvlSys:IsA("GuiObject") then
            parentGui = lvlSys
            lvlSys = nil
        end
    elseif parentGui == nil and type(lvlSys) == "table" and lvlSys.ClassName == "Frame" then
        parentGui = lvlSys
        lvlSys = nil
    end

    self.playerLevelSystem = pls or self.playerLevelSystem or PlayerLevelSystem
    self.levelSystem = lvlSys or self.levelSystem or LevelSystem

    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    self.gui = parentTarget

    if self.window then
        if self.window.Parent ~= parentTarget then
            parent(self.window, parentTarget)
        end
        self:update()
        self:setVisible(self.visible)
        return
    end

    self.window = GuiUtil.createWindow("LevelWindow")
    parent(self.window, parentTarget)

    self.levelLabel = createInstance("TextLabel")
    parent(self.levelLabel, self.window)
    if UDim2 and type(UDim2.new)=="function" then
        self.levelLabel.Position = UDim2.new(0,5,0,5)
        self.levelLabel.Size = UDim2.new(1,-10,0,20)
    end

    self.stageLabel = createInstance("TextLabel")
    parent(self.stageLabel, self.window)
    if UDim2 and type(UDim2.new)=="function" then
        self.stageLabel.Position = UDim2.new(0,5,0,30)
        self.stageLabel.Size = UDim2.new(1,-10,0,20)
    end

    self.milestoneLabel = createInstance("TextLabel")
    parent(self.milestoneLabel, self.window)
    if UDim2 and type(UDim2.new)=="function" then
        self.milestoneLabel.Position = UDim2.new(0,5,0,50)
        self.milestoneLabel.Size = UDim2.new(1,-10,0,20)
    end

    self:update()
    self:setVisible(self.visible)
end

function LevelUI:update()
    local gui = ensureGui()
    self.levelLabel = self.levelLabel or createInstance("TextLabel")
    parent(self.levelLabel, self.window or gui)
    self.stageLabel = self.stageLabel or createInstance("TextLabel")
    parent(self.stageLabel, self.window or gui)
    self.milestoneLabel = self.milestoneLabel or createInstance("TextLabel")
    parent(self.milestoneLabel, self.window or gui)

    local lvl = self.playerLevelSystem.level or 1
    local expPercent = math.floor((self.playerLevelSystem:getExpPercent() or 0)*100)
    local floor = self.levelSystem.currentLevel or 1
    local killsLeft = math.max(0,(self.levelSystem.requiredKills or 0) - (self.levelSystem.killCount or 0))

    self.levelLabel.Text = string.format("%s %d (%d%% XP)", LocalizationSystem:get("Level"), lvl, expPercent)
    self.stageLabel.Text = string.format("%s %d - %d %s", LocalizationSystem:get("Floor"), floor, killsLeft, LocalizationSystem:get("kills to"))
    if self.milestoneLabel then
        local nextLvl = self.playerLevelSystem:getNextMilestoneLevel()
        if nextLvl then
            self.milestoneLabel.Text = string.format("%s %d", LocalizationSystem:get("Next Milestone"), nextLvl)
        else
            self.milestoneLabel.Text = ""
        end
    end
end

function LevelUI:setVisible(on)
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

function LevelUI:toggle()
    if not self.gui then
        self:start(self.playerLevelSystem, self.levelSystem)
    end
    self:setVisible(not self.visible)
end

return LevelUI
