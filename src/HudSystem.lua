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
    partyButton = nil,
    scoreboardButton = nil,
    buttonFrame = nil,
    buttonLayout = nil,
    healthFrame = nil,
    healthFill = nil,
    healthText = nil,
    skillFrame = nil,
    skillLayout = nil,
    skillButtons = nil,
    cooldownLabels = nil,
    cooldowns = nil,
    playerHealth = nil,
    progressFrame = nil,
    progressFill = nil,
    progressText = nil,
    levelUpTimer = 0,
    deathTimer = 0,
    lastLevel = 1,
}

local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local GameManager = require(script.Parent:WaitForChild("GameManager"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local levelUpColor = Color3 and Color3.fromRGB(255, 240, 120) or {r=255,g=240,b=120}

local function createInstance(className)
    if HudSystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
            parent(self.buttonLayout, self.buttonFrame)
            parent(self.buttonFrame, gui)
            parent(self.autoButton, self.buttonFrame)
            parent(self.attackButton, self.buttonFrame)
            parent(self.gachaButton, self.buttonFrame)
            parent(self.inventoryButton, self.buttonFrame)
            parent(self.rewardButton, self.buttonFrame)
            parent(self.skillButton, self.buttonFrame)
            parent(self.companionButton, self.buttonFrame)
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
    self.partyButton = createInstance("TextButton")
    self.scoreboardButton = createInstance("TextButton")
    self.buttonFrame = createInstance("Frame")
    self.buttonLayout = createInstance("UIGridLayout")
    if Enum and Enum.FillDirection then
        self.buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        self.buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    if UDim2 and type(UDim2.new) == "function" then
        self.buttonLayout.CellSize = UDim2.new(0, 110, 0, 30)
        self.buttonLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        self.buttonFrame.Size = UDim2.new(0, 360, 0, 180)
        self.buttonFrame.Position = UDim2.new(0, 20, 1, -200)
    end
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
    self.partyButton.Text = "Party"
    self.scoreboardButton.Text = "Scores"

    self.healthFrame = createInstance("Frame")
    self.healthFill = createInstance("Frame")
    self.healthText = createInstance("TextLabel")
    self.skillFrame = createInstance("Frame")
    self.skillLayout = createInstance("UIListLayout")
    if Theme and Theme.colors then
        self.healthFill.BackgroundColor3 = Theme.colors.progressBar
    end
    if self.healthText.BackgroundTransparency ~= nil then
        self.healthText.BackgroundTransparency = 1
        self.healthText.TextScaled = true
    end
    self.skillButtons = {}
    self.cooldownLabels = {}
    self.cooldowns = {}
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
    GuiUtil.connectButton(self.partyButton, function()
        HudSystem:togglePartyUI()
    end)
    GuiUtil.connectButton(self.scoreboardButton, function()
        HudSystem:toggleScoreboard()
    end)
    parent(self.healthFill, self.healthFrame)
    parent(self.healthText, self.healthFrame)
    parent(self.healthFrame, gui)
    parent(self.skillLayout, self.skillFrame)
    parent(self.skillFrame, gui)
    parent(self.progressFill, self.progressFrame)
    parent(self.progressText, self.progressFrame)
    parent(self.progressFrame, gui)
    parent(self.levelLabel, gui)
    parent(self.currencyLabel, gui)
    parent(self.buttonLayout, self.buttonFrame)
    parent(self.buttonFrame, gui)
    parent(self.autoButton, self.buttonFrame)
    parent(self.attackButton, self.buttonFrame)
    parent(self.gachaButton, self.buttonFrame)
    parent(self.inventoryButton, self.buttonFrame)
    parent(self.rewardButton, self.buttonFrame)
    parent(self.skillButton, self.buttonFrame)
    parent(self.companionButton, self.buttonFrame)
    parent(self.questButton, self.buttonFrame)
    parent(self.progressButton, self.buttonFrame)
    parent(self.exchangeButton, self.buttonFrame)
    parent(self.dungeonButton, self.buttonFrame)
    parent(self.partyButton, self.buttonFrame)
    parent(self.scoreboardButton, self.buttonFrame)

    NetworkSystem:onClientEvent("StageAdvance", function(level)
        if HudSystem.progressText then
            HudSystem.progressText.Text = string.format("Lv.%d", level)
        end
    end)
    NetworkSystem:onClientEvent("StageRollback", function(level)
        if HudSystem.progressText then
            HudSystem.progressText.Text = string.format("Lv.%d", level)
        end
    end)
    NetworkSystem:onClientEvent("PlayerDied", function()
        HudSystem.deathTimer = 2
        if HudSystem.progressText then
            HudSystem.progressText.Text = "Respawning..."
        end
    end)
    NetworkSystem:onClientEvent("PlayerLevelUp", function(level)
        HudSystem.levelUpTimer = 1
        HudSystem.lastLevel = level
    end)
    NetworkSystem:onClientEvent("PlayerState", function(h)
        HudSystem.playerHealth = h
    end)
    NetworkSystem:onClientEvent("SkillCooldown", function(idx, cd)
        HudSystem.cooldowns[idx] = cd
    end)
    self:update()
end

function HudSystem:update(dt)
    dt = dt or 0
    local gui = ensureGui()
    self.progressFrame = self.progressFrame or createInstance("Frame")
    self.progressFill = self.progressFill or createInstance("Frame")
    self.progressText = self.progressText or createInstance("TextLabel")
    self.healthFrame = self.healthFrame or createInstance("Frame")
    self.healthFill = self.healthFill or createInstance("Frame")
    self.healthText = self.healthText or createInstance("TextLabel")
    self.skillFrame = self.skillFrame or createInstance("Frame")
    self.skillLayout = self.skillLayout or createInstance("UIListLayout")
    self.skillButtons = self.skillButtons or {}
    self.cooldownLabels = self.cooldownLabels or {}
    self.cooldowns = self.cooldowns or {}
    parent(self.progressFill, self.progressFrame)
    parent(self.progressText, self.progressFrame)
    parent(self.progressFrame, gui)
    parent(self.healthFill, self.healthFrame)
    parent(self.healthText, self.healthFrame)
    parent(self.healthFrame, gui)
    parent(self.skillLayout, self.skillFrame)
    parent(self.skillFrame, gui)
    self.buttonFrame = self.buttonFrame or createInstance("Frame")
    self.buttonLayout = self.buttonLayout or createInstance("UIGridLayout")
    if Enum and Enum.FillDirection then
        self.buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        self.buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    if UDim2 and type(UDim2.new) == "function" then
        self.buttonLayout.CellSize = UDim2.new(0, 110, 0, 30)
        self.buttonLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        self.buttonFrame.Size = UDim2.new(0, 360, 0, 180)
        self.buttonFrame.Position = UDim2.new(0, 20, 1, -200)
    end
    parent(self.buttonLayout, self.buttonFrame)
    parent(self.buttonFrame, gui)
    self.skillLayout = self.skillLayout or createInstance("UIListLayout")
    if Enum and Enum.FillDirection then
        self.skillLayout.FillDirection = Enum.FillDirection.Horizontal
        self.skillLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

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

    local hp = self.playerHealth or PlayerSystem.health or PlayerSystem.maxHealth
    local maxHp = PlayerSystem.maxHealth or 100
    local hpRatio = maxHp > 0 and hp / maxHp or 0
    self.healthText.Text = string.format("%d/%d", hp, maxHp)
    if UDim2 and type(UDim2.new)=="function" then
        self.healthFill.Size = UDim2.new(hpRatio, 0, 1, 0)
    else
        self.healthFill.FillRatio = hpRatio
    end

    self.autoButton = self.autoButton or createInstance("TextButton")
    parent(self.autoButton, self.buttonFrame)
    local state = AutoBattleSystem.enabled and "ON" or "OFF"
    self.autoButton.Text = "Auto: " .. state

    self.attackButton = self.attackButton or createInstance("TextButton")
    parent(self.attackButton, self.buttonFrame)
    self.attackButton.Text = "Attack"
    if AutoBattleSystem.enabled then
        self.attackButton.Active = false
    else
        self.attackButton.Active = true
    end

    self.gachaButton = self.gachaButton or createInstance("TextButton")
    parent(self.gachaButton, self.buttonFrame)
    self.gachaButton.Text = "Gacha"

    self.inventoryButton = self.inventoryButton or createInstance("TextButton")
    parent(self.inventoryButton, self.buttonFrame)
    self.inventoryButton.Text = "Inventory"

    self.rewardButton = self.rewardButton or createInstance("TextButton")
    parent(self.rewardButton, self.buttonFrame)
    self.rewardButton.Text = string.format("Rewards %d/%d", RewardGaugeSystem.gauge, RewardGaugeSystem.maxGauge)

    self.skillButton = self.skillButton or createInstance("TextButton")
    parent(self.skillButton, self.buttonFrame)
    self.skillButton.Text = "Skills"

    self.companionButton = self.companionButton or createInstance("TextButton")
    parent(self.companionButton, self.buttonFrame)
    self.companionButton.Text = "Companions"

    self.questButton = self.questButton or createInstance("TextButton")
    parent(self.questButton, self.buttonFrame)
    self.questButton.Text = "Quests"

    self.progressButton = self.progressButton or createInstance("TextButton")
    parent(self.progressButton, self.buttonFrame)
    self.progressButton.Text = "Map"

    self.exchangeButton = self.exchangeButton or createInstance("TextButton")
    parent(self.exchangeButton, self.buttonFrame)
    self.exchangeButton.Text = "Exchange"

    self.dungeonButton = self.dungeonButton or createInstance("TextButton")
    parent(self.dungeonButton, self.buttonFrame)
    self.dungeonButton.Text = "Dungeon"

    self.partyButton = self.partyButton or createInstance("TextButton")
    parent(self.partyButton, self.buttonFrame)
    self.partyButton.Text = "Party"

    self.scoreboardButton = self.scoreboardButton or createInstance("TextButton")
    parent(self.scoreboardButton, self.buttonFrame)
    self.scoreboardButton.Text = "Scores"

    local skills = GameManager and GameManager.skillSystem and GameManager.skillSystem.skills or {}
    for i = 1, math.min(4, #skills) do
        local skill = skills[i]
        local btn = self.skillButtons[i]
        if not btn then
            btn = createInstance("ImageButton")
            btn.Name = "Skill" .. i
            if UDim2 and type(UDim2.new)=="function" then
                btn.Size = UDim2.new(0, 60, 0, 60)
            end
            btn.LayoutOrder = i
            GuiUtil.connectButton(btn, function()
                NetworkSystem:fireServer("SkillRequest", i)
            end)
            parent(btn, self.skillFrame)
            self.skillButtons[i] = btn
        end
        btn.Image = skill.image or ""
        local cdLabel = self.cooldownLabels[i]
        if not cdLabel then
            cdLabel = createInstance("TextLabel")
            cdLabel.BackgroundTransparency = 0.5
            cdLabel.Size = UDim2.new(1,0,1,0)
            cdLabel.TextScaled = true
            cdLabel.TextColor3 = Theme and Theme.colors.labelText or Color3.new(1,1,1)
            cdLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
            cdLabel.TextXAlignment = Enum and Enum.TextXAlignment.Center or cdLabel.TextXAlignment
            cdLabel.TextYAlignment = Enum and Enum.TextYAlignment.Center or cdLabel.TextYAlignment
            parent(cdLabel, btn)
            self.cooldownLabels[i] = cdLabel
        end
        self.cooldowns[i] = self.cooldowns[i] or 0
    end

    local ratio = nextExp > 0 and exp / nextExp or 0
    if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
    if self.deathTimer > 0 then
        self.deathTimer = math.max(0, self.deathTimer - dt)
        self.progressText.Text = "Respawning..."
    else
        self.progressText.Text = string.format("Lv.%d", lvl)
    end
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

    for i, cd in pairs(self.cooldowns) do
        if cd > 0 then
            self.cooldowns[i] = math.max(0, cd - dt)
            if self.cooldownLabels[i] then
                self.cooldownLabels[i].Text = tostring(math.ceil(self.cooldowns[i]))
                self.cooldownLabels[i].Visible = true
            end
        elseif self.cooldownLabels[i] then
            self.cooldownLabels[i].Visible = false
            self.cooldownLabels[i].Text = ""
        end
    end

    if UDim2 and type(UDim2.new)=="function" then
        self.levelLabel.Position = UDim2.new(0, 20, 0, 10)
        self.currencyLabel.Position = UDim2.new(0, 20, 0, 30)
        if not self.buttonFrame.Size then
            self.buttonFrame.Size = UDim2.new(0, 360, 0, 180)
            self.buttonFrame.Position = UDim2.new(0, 20, 1, -200)
        end
        self.healthFrame.Position = UDim2.new(0, 20, 0, 50)
        self.healthFrame.Size = UDim2.new(0, 200, 0, 20)
        self.skillFrame.Position = UDim2.new(0.5, -150, 1, -80)
        self.skillFrame.Size = UDim2.new(0, 300, 0, 60)
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

function HudSystem:togglePartyUI()
    local PartyUISystem = require(script.Parent:WaitForChild("PartyUISystem"))
    PartyUISystem:toggle()
end

function HudSystem:toggleScoreboard()
    local ScoreboardUISystem = require(script.Parent:WaitForChild("ScoreboardUISystem"))
    ScoreboardUISystem:toggle()
end

return HudSystem
