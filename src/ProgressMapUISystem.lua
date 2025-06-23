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
local LootSystem = require(script.Parent:WaitForChild("LootSystem"))
local LocalizationSystem = require(script.Parent:WaitForChild("LocalizationSystem"))

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
end

function ProgressMapUI:update()
    local ps = self.progressSystem
    if not ps then return end
    local gui = ensureGui()
    self.label = self.label or createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.label.Position = UDim2.new(0, 5, 0, 5)
        self.label.Size = UDim2.new(1, -10, 1, -10)
    end
    parent(self.label, self.window or gui)
    local pr = ps:getProgress()
    local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
    local _, stageType, killsLeft, bossName, milestoneKills, milestoneType = LevelSystem:getNextStageInfo()
    local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
    local loc = LocationSystem:getCurrent()
    local typeLabel = stageType or ""
    if bossName then
        typeLabel = bossName
    elseif stageType == "mini" then
        typeLabel = LocalizationSystem:get("Mini Boss")
    elseif stageType == "boss" then
        typeLabel = LocalizationSystem:get("Boss")
    elseif stageType == "location" then
        typeLabel = LocalizationSystem:get("Area Boss")
    end
    local reward = LootSystem.getRewardInfo(stageType)
    local currency = LootSystem.getCurrencyType()
    local locName = loc and loc.name or ""
    local parts = {
        string.format("%s: %s", LocalizationSystem:get("Location"), locName),
        string.format("%s %d", LocalizationSystem:get("Floor"), pr.stage),
        string.format("%d %s %s", killsLeft, LocalizationSystem:get("kills to"), typeLabel),
    }
    if milestoneKills and milestoneType then
        local mLabel = milestoneType
        if milestoneType == "mini" then
            mLabel = LocalizationSystem:get("Mini Boss")
        elseif milestoneType == "boss" then
            mLabel = LocalizationSystem:get("Boss")
        elseif milestoneType == "location" then
            mLabel = LocalizationSystem:get("Area Boss")
        end
        table.insert(parts, string.format("%d %s %s", milestoneKills, LocalizationSystem:get("kills to"), mLabel))
    end
    table.insert(parts, string.format("+%d %s", reward.coins * (LevelSystem.currentLevel or 1), currency))
    table.insert(parts, string.format("+%d XP", reward.exp))
    if reward.ether and reward.ether > 0 then
        table.insert(parts, string.format("+%d %s", reward.ether, LocalizationSystem:get("Ether")))
    end
    if reward.crystals and reward.crystals > 0 then
        table.insert(parts, string.format("+%d %s", reward.crystals, LocalizationSystem:get("Crystals")))
    end
    if reward.gauge and reward.gauge > 0 then
        table.insert(parts, string.format("+%d %s", reward.gauge, LocalizationSystem:get("Gauge")))
    end
    local gauge = require(script.Parent:WaitForChild("RewardGaugeSystem"))
    local percent = math.floor((gauge:getPercent() or 0) * 100)
    table.insert(parts, string.format("%d%% %s", percent, LocalizationSystem:get("Gauge")))
    self.label.Text = table.concat(parts, " | ")
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
