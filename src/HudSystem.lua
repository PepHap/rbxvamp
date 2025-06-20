-- HudSystem.lua
-- Displays player level, experience and currency in a simple GUI

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local HudSystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    levelLabel = nil,
    currencyLabel = nil,
    autoButton = nil,
    attackButton = nil,
    gachaButton = nil,
    inventoryButton = nil,
    rewardButton = nil,
    skillButton = nil,
    companionButton = nil,
    questButton = nil,
    progressButton = nil,
    exchangeButton = nil,
    dungeonButton = nil,
    progressFrame = nil,
    progressFill = nil,
    progressText = nil,
    levelUpTimer = 0,
    lastLevel = 1,
}

local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local levelUpColor = Color3 and Color3.fromRGB(255, 240, 120) or {r=255,g=240,b=120}

local function createInstance(className)
    if HudSystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if HudSystem.gui and (not HudSystem.useRobloxObjects or HudSystem.gui.Parent) then
        return HudSystem.gui
    end
    local pgui
    if HudSystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("HudUI")
            if existing then
                HudSystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "HudUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    HudSystem.gui = gui
    if HudSystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function HudSystem:start()
    local gui = ensureGui()
    if self.levelLabel then
        if self.levelLabel.Parent ~= gui then
            parent(self.levelLabel, gui)
            parent(self.currencyLabel, gui)
            parent(self.autoButton, gui)
            parent(self.attackButton, gui)
            parent(self.gachaButton, gui)
            parent(self.inventoryButton, gui)
            parent(self.rewardButton, gui)
            parent(self.skillButton, gui)
            parent(self.companionButton, gui)
            parent(self.progressFrame, gui)
        end
        return
    end
    self.levelLabel = createInstance("TextLabel")
    self.currencyLabel = createInstance("TextLabel")
    self.autoButton = createInstance("TextButton")
    self.attackButton = createInstance("TextButton")
    self.gachaButton = createInstance("TextButton")
    self.inventoryButton = createInstance("TextButton")
    self.rewardButton = createInstance("TextButton")
    self.skillButton = createInstance("TextButton")
    self.companionButton = createInstance("TextButton")
    self.questButton = createInstance("TextButton")
    self.progressButton = createInstance("TextButton")
    self.exchangeButton = createInstance("TextButton")
    self.dungeonButton = createInstance("TextButton")
    self.progressFrame = createInstance("Frame")
    self.progressFill = createInstance("Frame")
    self.progressText = createInstance("TextLabel")
    self.progressText.Text = "Lv.1"
    self.autoButton.Text = "Auto: OFF"
    self.attackButton.Text = "Attack"
    self.gachaButton.Text = "Gacha"
    self.inventoryButton.Text = "Inventory"
    self.rewardButton.Text = "Rewards"
    self.skillButton.Text = "Skills"
    self.companionButton.Text = "Companions"
    self.questButton.Text = "Quests"
    self.progressButton.Text = "Map"
    self.exchangeButton.Text = "Exchange"
    self.dungeonButton.Text = "Dungeon"
    GuiUtil.connectButton(self.autoButton, function()
        HudSystem:toggleAutoBattle()
    end)
    GuiUtil.connectButton(self.attackButton, function()
        HudSystem:manualAttack()
    end)
    GuiUtil.connectButton(self.gachaButton, function()
        HudSystem:toggleGacha()
    end)
    GuiUtil.connectButton(self.inventoryButton, function()
        HudSystem:toggleInventory()
    end)
    GuiUtil.connectButton(self.rewardButton, function()
        HudSystem:toggleRewardGauge()
    end)
    GuiUtil.connectButton(self.skillButton, function()
        HudSystem:toggleSkillUI()
    end)
    GuiUtil.connectButton(self.companionButton, function()
        HudSystem:toggleCompanionUI()
    end)
    GuiUtil.connectButton(self.questButton, function()
        HudSystem:toggleQuestUI()
    end)
    GuiUtil.connectButton(self.progressButton, function()
        HudSystem:toggleProgressMap()
    end)
    GuiUtil.connectButton(self.exchangeButton, function()
        HudSystem:toggleExchangeUI()
    end)
    GuiUtil.connectButton(self.dungeonButton, function()
        HudSystem:toggleDungeonUI()
    end)
    parent(self.progressFill, self.progressFrame)
    parent(self.progressText, self.progressFrame)
    parent(self.progressFrame, gui)
    parent(self.levelLabel, gui)
    parent(self.currencyLabel, gui)
    parent(self.autoButton, gui)
    parent(self.attackButton, gui)
    parent(self.gachaButton, gui)
    parent(self.inventoryButton, gui)
    parent(self.rewardButton, gui)
    parent(self.skillButton, gui)
    parent(self.companionButton, gui)
    parent(self.questButton, gui)
    parent(self.progressButton, gui)
    parent(self.exchangeButton, gui)
    parent(self.dungeonButton, gui)
    self:update()
end

function HudSystem:update(dt)
    dt = dt or 0
    local gui = ensureGui()
    self.progressFrame = self.progressFrame or createInstance("Frame")
    self.progressFill = self.progressFill or createInstance("Frame")
    self.progressText = self.progressText or createInstance("TextLabel")
    parent(self.progressFill, self.progressFrame)
    parent(self.progressText, self.progressFrame)
    parent(self.progressFrame, gui)
    self.levelLabel = self.levelLabel or createInstance("TextLabel")
    parent(self.levelLabel, gui)
    local lvl = PlayerLevelSystem.level or 1
    local exp = PlayerLevelSystem.exp or 0
    local nextExp = PlayerLevelSystem.nextExp or 0
    if lvl > (self.lastLevel or 1) then
        self.levelUpTimer = 1
        self.lastLevel = lvl
    end
    self.levelLabel.Text = string.format("Lv.%d %d/%d EXP", lvl, exp, nextExp)

    self.currencyLabel = self.currencyLabel or createInstance("TextLabel")
    parent(self.currencyLabel, gui)
    local loc = LocationSystem:getCurrent()
    local currencyType = loc and loc.currency or "gold"
    local amount = CurrencySystem:get(currencyType)
    self.currencyLabel.Text = string.format("%s: %d", currencyType, amount)

    self.autoButton = self.autoButton or createInstance("TextButton")
    parent(self.autoButton, gui)
    local state = AutoBattleSystem.enabled and "ON" or "OFF"
    self.autoButton.Text = "Auto: " .. state

    self.attackButton = self.attackButton or createInstance("TextButton")
    parent(self.attackButton, gui)
    self.attackButton.Text = "Attack"
    if AutoBattleSystem.enabled then
        self.attackButton.Active = false
    else
        self.attackButton.Active = true
    end

    self.gachaButton = self.gachaButton or createInstance("TextButton")
    parent(self.gachaButton, gui)
    self.gachaButton.Text = "Gacha"

    self.inventoryButton = self.inventoryButton or createInstance("TextButton")
    parent(self.inventoryButton, gui)
    self.inventoryButton.Text = "Inventory"

    self.rewardButton = self.rewardButton or createInstance("TextButton")
    parent(self.rewardButton, gui)
    self.rewardButton.Text = string.format("Rewards %d/%d", RewardGaugeSystem.gauge, RewardGaugeSystem.maxGauge)

    self.skillButton = self.skillButton or createInstance("TextButton")
    parent(self.skillButton, gui)
    self.skillButton.Text = "Skills"

    self.companionButton = self.companionButton or createInstance("TextButton")
    parent(self.companionButton, gui)
    self.companionButton.Text = "Companions"

    self.questButton = self.questButton or createInstance("TextButton")
    parent(self.questButton, gui)
    self.questButton.Text = "Quests"

    self.progressButton = self.progressButton or createInstance("TextButton")
    parent(self.progressButton, gui)
    self.progressButton.Text = "Map"

    self.exchangeButton = self.exchangeButton or createInstance("TextButton")
    parent(self.exchangeButton, gui)
    self.exchangeButton.Text = "Exchange"

    self.dungeonButton = self.dungeonButton or createInstance("TextButton")
    parent(self.dungeonButton, gui)
    self.dungeonButton.Text = "Dungeon"

    local ratio = nextExp > 0 and exp / nextExp or 0
    if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
    self.progressText.Text = string.format("Lv.%d", lvl)
    if UDim2 and type(UDim2.new)=="function" then
        self.progressFrame.Position = UDim2.new(0.5, -200, 0, 0)
        self.progressFrame.Size = UDim2.new(0, 400, 0, 20)
        local fillColor = Color3.fromRGB(80, 120, 220)
        if self.levelUpTimer > 0 then
            self.levelUpTimer = math.max(0, self.levelUpTimer - dt)
            fillColor = levelUpColor
        end
        self.progressFill.BackgroundColor3 = fillColor
        self.progressFill.Size = UDim2.new(ratio, 0, 1, 0)
        self.progressText.Size = UDim2.new(1, 0, 1, 0)
        self.progressText.BackgroundTransparency = 1
        self.progressText.TextScaled = true
    else
        if self.levelUpTimer > 0 then
            self.levelUpTimer = math.max(0, self.levelUpTimer - dt)
            self.progressFill.color = levelUpColor
        else
            self.progressFill.color = nil
        end
        self.progressFill.FillRatio = ratio
    end

    if UDim2 and type(UDim2.new)=="function" then
        self.levelLabel.Position = UDim2.new(0, 20, 0, 10)
        self.currencyLabel.Position = UDim2.new(0, 20, 0, 30)
        self.autoButton.Position = UDim2.new(0, 20, 1, -120)
        self.attackButton.Position = UDim2.new(0, 20, 1, -40)
        self.gachaButton.Position = UDim2.new(0, 20, 1, -80)
        self.inventoryButton.Position = UDim2.new(0, 120, 1, -80)
        self.rewardButton.Position = UDim2.new(0, 220, 1, -80)
        self.skillButton.Position = UDim2.new(0, 320, 1, -80)
        self.companionButton.Position = UDim2.new(0, 420, 1, -80)
        self.questButton.Position = UDim2.new(0, 520, 1, -80)
        self.progressButton.Position = UDim2.new(0, 620, 1, -80)
        self.exchangeButton.Position = UDim2.new(0, 720, 1, -80)
        self.dungeonButton.Position = UDim2.new(0, 820, 1, -80)
    end
end

function HudSystem:toggleAutoBattle()
    if AutoBattleSystem.enabled then
        AutoBattleSystem:disable()
    else
        AutoBattleSystem:enable()
    end
    self:update()
end

function HudSystem:manualAttack()
    if AutoBattleSystem.enabled then
        return
    end
    local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
    PlayerInputSystem:manualAttack()
end

function HudSystem:toggleGacha()
    local GachaUISystem = require(script.Parent:WaitForChild("GachaUISystem"))
    GachaUISystem:toggle()
end

function HudSystem:toggleInventory()
    local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
    InventoryUISystem:toggle()
end

function HudSystem:toggleRewardGauge()
    local RewardGaugeUISystem = require(script.Parent:WaitForChild("RewardGaugeUISystem"))
    RewardGaugeUISystem:toggle()
end

function HudSystem:toggleSkillUI()
    local SkillUISystem = require(script.Parent:WaitForChild("SkillUISystem"))
    SkillUISystem:toggle()
end

function HudSystem:toggleCompanionUI()
    local CompanionUISystem = require(script.Parent:WaitForChild("CompanionUISystem"))
    CompanionUISystem:toggle()
end

function HudSystem:toggleQuestUI()
    local QuestUISystem = require(script.Parent:WaitForChild("QuestUISystem"))
    QuestUISystem:toggle()
end

function HudSystem:toggleProgressMap()
    local ProgressMapUISystem = require(script.Parent:WaitForChild("ProgressMapUISystem"))
    ProgressMapUISystem:toggle()
end

function HudSystem:toggleExchangeUI()
    local CrystalExchangeUISystem = require(script.Parent:WaitForChild("CrystalExchangeUISystem"))
    CrystalExchangeUISystem:toggle()
end

function HudSystem:toggleDungeonUI()
    local DungeonUISystem = require(script.Parent:WaitForChild("DungeonUISystem"))
    DungeonUISystem:toggle()
end

return HudSystem
