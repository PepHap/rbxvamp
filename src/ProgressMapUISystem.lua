-- ProgressMapUISystem.lua
-- Simple UI displaying progress through locations and stages.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ProgressMapUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local ProgressMapUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    label = nil,
    progressSystem = nil,
    visible = false,
    connections = {},
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local rewards = {
    normal   = {coins = 1,  exp = 5,   gauge = 10, ether = 0, crystals = 0},
    mini     = {coins = 5,  exp = 20,  gauge = 20, ether = 1, crystals = 1},
    boss     = {coins = 10, exp = 50,  gauge = 30, ether = 2, crystals = 2},
    location = {coins = 20, exp = 100, gauge = 50, ether = 3, crystals = 3},
}

local function getRewardInfo(enemyType)
    return rewards[enemyType or "normal"] or rewards.normal
end

local function getCurrencyType()
    local loc = LocationSystem:getCurrent()
    if loc and loc.currency then
        return loc.currency
    end
    return "gold"
end
local LocalizationSystem = require(script.Parent:WaitForChild("LocalizationSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if ProgressMapUI.useRobloxObjects and typeof ~= nil and Instance and type(Instance.new)=="function" then
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
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
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
    self.gui = gui
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
        self.window.AnchorPoint = Vector2.new(0, 0)
        self.window.Position = UDim2.new(0, 0, 0, 0)
        self.window.Size = UDim2.new(1, 0, 1, 0)
        GuiUtil.clampToScreen(self.window)
    end
    parent(self.window, gui)

    local closeBtn = createInstance("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Text = "X"
    if UDim2 and type(UDim2.new)=="function" then
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -25, 0, 5)
    end
    parent(closeBtn, self.window)
    GuiUtil.connectButton(closeBtn, function()
        ProgressMapUI:setVisible(false)
    end)

    self.label = createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.label.Position = UDim2.new(0, 5, 0, 5)
        self.label.Size = UDim2.new(1, -10, 1, -10)
    end
    parent(self.label, self.window)
    self:update()
    self:setVisible(self.visible)

    if NetworkSystem and NetworkSystem.onClientEvent then
        if not self.connections.levelProgress then
            self.connections.levelProgress = NetworkSystem:onClientEvent("LevelProgress", function()
                ProgressMapUI:update()
            end)
        end
        if not self.connections.stageAdvance then
            self.connections.stageAdvance = NetworkSystem:onClientEvent("StageAdvance", function()
                ProgressMapUI:update()
            end)
        end
        if not self.connections.stageRollback then
            self.connections.stageRollback = NetworkSystem:onClientEvent("StageRollback", function()
                ProgressMapUI:update()
            end)
        end
    end
end

function ProgressMapUI:update()
    local gui = ensureGui()
    self.label = self.label or createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.label.Position = UDim2.new(0, 5, 0, 5)
        self.label.Size = UDim2.new(1, -10, 1, -10)
    end
    parent(self.label, self.window or gui)

    local ps = self.progressSystem
    if not ps then
        -- Display a message when no progress system is available
        self.label.Text = "Progress unavailable"
        return
    end
    local pr = ps:getProgress()
    if not pr then
        self.label.Text = "No progress data"
        return
    end
    local LevelSystem = require(script.Parent:WaitForChild("ClientLevelSystem"))
    local nextLevel, stageType, killsLeft, bossName, milestoneKills, milestoneType = LevelSystem:getNextStageInfo()
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
    local reward = getRewardInfo(stageType)
    local currency = getCurrencyType()
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
    local coinLevel = nextLevel or (LevelSystem.currentLevel or 1)
    table.insert(parts, string.format("+%d %s", reward.coins * coinLevel, currency))
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
    local gauge = require(script.Parent:WaitForChild("ClientRewardGaugeSystem"))
    local percent = math.floor((gauge:getPercent() or 0) * 100)
    table.insert(parts, string.format("%d%% %s", percent, LocalizationSystem:get("Gauge")))
    table.insert(parts, string.format("%s: +%d %s", LocalizationSystem:get("Next Reward"), reward.exp, LocalizationSystem:get("XP")))
    self.label.Text = table.concat(parts, " | ")
end

function ProgressMapUI:setVisible(on)
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
    GuiUtil.makeFullScreen(parentGui)
    GuiUtil.clampToScreen(parentGui)
end

function ProgressMapUI:toggle()
    if not self.gui then
        self:start(self.progressSystem)
    end
    self:setVisible(not self.visible)
end

return ProgressMapUI
