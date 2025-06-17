-- HudSystem.lua
-- Displays player level, experience and currency in a simple GUI

local HudSystem = {
    useRobloxObjects = false,
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
    progressFrame = nil,
    progressFill = nil,
    progressText = nil,
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
    if not child or not parentObj then
        return
    end
    if typeof and typeof(child) == "Instance" then
        if typeof(parentObj) == "Instance" then
            child.Parent = parentObj
        end
    else
        child.Parent = parentObj
    end
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if HudSystem.gui then
        return HudSystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "HudUI"
    HudSystem.gui = gui
    if HudSystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function HudSystem:start()
    local gui = ensureGui()
    self.levelLabel = createInstance("TextLabel")
    self.currencyLabel = createInstance("TextLabel")
    self.autoButton = createInstance("TextButton")
    self.attackButton = createInstance("TextButton")
    self.gachaButton = createInstance("TextButton")
    self.inventoryButton = createInstance("TextButton")
    self.rewardButton = createInstance("TextButton")
    self.skillButton = createInstance("TextButton")
    self.companionButton = createInstance("TextButton")
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
    self:update()
end

function HudSystem:update()
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

    local ratio = nextExp > 0 and exp / nextExp or 0
    if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
    self.progressText.Text = string.format("Lv.%d", lvl)
    if UDim2 and UDim2.new then
        self.progressFrame.Position = UDim2.new(0.5, -200, 0, 0)
        self.progressFrame.Size = UDim2.new(0, 400, 0, 20)
        self.progressFill.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
        self.progressFill.Size = UDim2.new(ratio, 0, 1, 0)
        self.progressText.Size = UDim2.new(1, 0, 1, 0)
        self.progressText.BackgroundTransparency = 1
        self.progressText.TextScaled = true
    else
        self.progressFill.FillRatio = ratio
    end

    if UDim2 and UDim2.new then
        self.levelLabel.Position = UDim2.new(0, 20, 0, 10)
        self.currencyLabel.Position = UDim2.new(0, 20, 0, 30)
        self.autoButton.Position = UDim2.new(0, 20, 1, -120)
        self.attackButton.Position = UDim2.new(0, 20, 1, -40)
        self.gachaButton.Position = UDim2.new(0, 20, 1, -80)
        self.inventoryButton.Position = UDim2.new(0, 120, 1, -80)
        self.rewardButton.Position = UDim2.new(0, 220, 1, -80)
        self.skillButton.Position = UDim2.new(0, 320, 1, -80)
        self.companionButton.Position = UDim2.new(0, 420, 1, -80)
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

return HudSystem
