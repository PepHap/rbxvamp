-- ProgressMapUISystem.lua
-- Simple UI displaying progress through locations and stages.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local ProgressMapUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    label = nil,
    progressSystem = nil,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local L = require(script.Parent:WaitForChild("LocalizationUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local function createInstance(className)
    if ProgressMapUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if ProgressMapUI.gui and (not ProgressMapUI.useRobloxObjects or ProgressMapUI.gui.Parent) then
        return ProgressMapUI.gui
    end
    local pgui
    if ProgressMapUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("ProgressMapUI")
            if existing then
                ProgressMapUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "ProgressMapUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    ProgressMapUI.gui = gui
    if ProgressMapUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function ProgressMapUI:start(ps)
    self.progressSystem = ps or self.progressSystem or require(script.Parent:WaitForChild("ProgressMapSystem"))
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        self:update()
        self:setVisible(self.visible)
        return
    end
    self.window = GuiUtil.createWindow("ProgressMapWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.Size = UDim2.new(0, 250, 0, 80)
        self.window.Position = UDim2.new(0.5, -125, 0, 20)
    end
    parent(self.window, gui)
    self.label = createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.label.Position = UDim2.new(0, 5, 0, 5)
        self.label.Size = UDim2.new(1, -10, 1, -10)
    end
    parent(self.label, self.window)
    self:update()
    self:setVisible(self.visible)

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("LevelProgress", function(lvl, kills, req)
            LevelSystem.currentLevel = lvl
            LevelSystem.killCount = kills
            LevelSystem.requiredKills = req
            ProgressMapUI:update()
        end)
    end
end

function ProgressMapUI:update()
    local ps = self.progressSystem
    if not ps then return end
    local gui = ensureGui()
    self.label = self.label or createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.label.Position = UDim2.new(0, 5, 0, 5)
        self.label.Size = UDim2.new(1, -10, 1, -10)
        self.label.TextWrapped = true
    end
    parent(self.label, self.window or gui)
    local pr = ps:getProgress()
    local remain = LevelSystem:getRemainingKills()
    local stageType = LevelSystem.getStageType(LevelSystem.currentLevel + 1)
    local reward = LevelSystem:getNextStageReward()
    local rewardText = ""
    if reward then
        rewardText = string.format("%d %s", reward.amount, reward.currency)
    end
    local enemyMsg = L.translate("enemiesLeft") .. ": " .. remain
    if stageType == "mini" then
        enemyMsg = L.translate("enemiesLeft") .. " to mini-boss: " .. remain
    elseif stageType == "boss" or stageType == "location" then
        enemyMsg = L.translate("enemiesLeft") .. " to boss: " .. remain
    end
    self.label.Text = string.format("Location %d - %s %d\n%s\n%s: %s",
        pr.location, L.translate("floor"), pr.stage, enemyMsg,
        L.translate("nextReward"), rewardText)
end

function ProgressMapUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function ProgressMapUI:toggle()
    if not self.gui then
        self:start(self.progressSystem)
    end
    self:setVisible(not self.visible)
end

return ProgressMapUI
