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
    menuButton = nil,
    buttonFrame = nil,
    buttonLayout = nil,
    healthFrame = nil,
    healthFill = nil,
    healthText = nil,
    skillFrame = nil,
    skillLayout = nil,
    skillButtons = nil,
    cooldownOverlays = nil,
    cooldownLabels = nil,
    cooldowns = nil,
    maxCooldowns = nil,
    playerHealth = nil,
    autoEnabled = false,
    progressFrame = nil,
    progressFill = nil,
    progressText = nil,
    levelUpTimer = 0,
    deathTimer = 0,
    lastLevel = 1,
}

local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem.client"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local RunService = game:GetService("RunService")
local RewardGaugeSystem = require(script.Parent:WaitForChild("ClientRewardGaugeSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local GameManager = require(script.Parent:WaitForChild("ClientGameManager"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local menuIcons = require(assets:WaitForChild("menu_icons"))
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
            elseif className == "ImageButton" then Theme.styleImageButton(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "ImageButton" then Theme.styleImageButton(tbl)
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
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    HudSystem.gui = gui
    if HudSystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function HudSystem:start()
    local gui = ensureGui()
    NetworkSystem:onClientEvent("AutoBattleToggle", function(enabled)
        self.autoEnabled = not not enabled
        self:update()
    end)
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
    self.gachaButton = createInstance("ImageButton")
    self.inventoryButton = createInstance("ImageButton")
    self.rewardButton = createInstance("ImageButton")
    self.skillButton = createInstance("ImageButton")
    self.companionButton = createInstance("ImageButton")
    self.questButton = createInstance("ImageButton")
    self.progressButton = createInstance("ImageButton")
    self.exchangeButton = createInstance("ImageButton")
    self.dungeonButton = createInstance("ImageButton")
    self.partyButton = createInstance("ImageButton")
    self.scoreboardButton = createInstance("ImageButton")
    self.menuButton = createInstance("ImageButton")
    self.buttonFrame = createInstance("Frame")
    GuiUtil.addCrossDecor(self.buttonFrame)
    self.buttonLayout = createInstance("UIGridLayout")
    if Enum and Enum.FillDirection then
        self.buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        self.buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    if UDim2 and type(UDim2.new) == "function" then
        self.buttonLayout.CellSize = UDim2.new(0, 60, 0, 60)
        self.buttonLayout.CellPadding = UDim2.new(0, 4, 0, 4)
        self.buttonFrame.Size = UDim2.new(0.22, 0, 0.25, 0)
        self.buttonFrame.Position = UDim2.new(0.02, 0, 0.96, 0)
        self.buttonFrame.AnchorPoint = Vector2.new(0, 1)
    end
    GuiUtil.applyResponsive(self.buttonFrame, nil, 240, 60, 400, 120)
    self.progressFrame = createInstance("Frame")
    self.progressFill = createInstance("Frame")
    self.progressText = createInstance("TextLabel")
    if self.progressFrame.FindFirstChild and not self.progressFrame:FindFirstChild("Top") then
        GuiUtil.addCrossDecor(self.progressFrame)
    end
    self.progressText.Text = "Lv.1"
    self.autoButton.Text = "Auto: OFF"
    self.attackButton.Text = "Attack"
    self.gachaButton.Image = menuIcons.Gacha
    self.inventoryButton.Image = menuIcons.Inventory
    self.rewardButton.Image = menuIcons.Reward
    self.skillButton.Image = menuIcons.Skills
    self.companionButton.Image = menuIcons.Companions
    self.questButton.Image = menuIcons.Quests
    self.progressButton.Image = menuIcons.Map
    self.exchangeButton.Image = menuIcons.Exchange
    self.dungeonButton.Image = menuIcons.Dungeons
    self.partyButton.Image = menuIcons.Party
    self.scoreboardButton.Image = menuIcons.Scoreboard
    self.menuButton.Image = menuIcons.Menu

    self.healthFrame = createInstance("Frame")
    self.healthFill = createInstance("Frame")
    self.healthText = createInstance("TextLabel")
    self.skillFrame = createInstance("Frame")
    if self.healthFrame.FindFirstChild and not self.healthFrame:FindFirstChild("Top") then
        GuiUtil.addCrossDecor(self.healthFrame)
    end
    if self.skillFrame.FindFirstChild and not self.skillFrame:FindFirstChild("Top") then
        GuiUtil.addCrossDecor(self.skillFrame)
    end
    self.skillLayout = createInstance("UIListLayout")
    if self.skillLayout.Padding ~= nil then
        self.skillLayout.Padding = UDim.new(0, 4)
    end
    if Theme and Theme.styleProgressBar then
        Theme.styleProgressBar(self.progressFrame)
        Theme.styleProgressBar(self.healthFrame)
    end
    GuiUtil.applyResponsive(self.healthFrame, 10, 150, 20, 800, 40)
    GuiUtil.applyResponsive(self.progressFrame, 16, 200, 20, 1000, 40)
    -- Keep the skill bar a fixed height while scaling for different resolutions
    -- Reserve extra width so four 60x60 icons fit with padding
    GuiUtil.applyResponsive(self.skillFrame, nil, 252, 60, 252, 60)
    if UDim2 and type(UDim2.new) == "function" then
        self.progressFrame.AnchorPoint = Vector2.new(0.5, 0)
        self.skillFrame.AnchorPoint = Vector2.new(1, 1)
        self.healthFrame.AnchorPoint = Vector2.new(0, 0)
    end
    if Theme and Theme.colors then
        self.healthFill.BackgroundColor3 = Theme.colors.progressBar
    end
    if self.healthText.BackgroundTransparency ~= nil then
        self.healthText.BackgroundTransparency = 1
        self.healthText.TextScaled = true
    end
    self.skillButtons = {}
    self.cooldownOverlays = {}
    self.cooldownLabels = {}
    self.cooldowns = {}
    self.maxCooldowns = {}
    GuiUtil.connectButton(self.autoButton, function()
        HudSystem:toggleAutoBattle()
    end)
    GuiUtil.applyHoverEffect(self.autoButton)
    GuiUtil.connectButton(self.attackButton, function()
        HudSystem:manualAttack()
    end)
    GuiUtil.applyHoverEffect(self.attackButton)
    GuiUtil.connectButton(self.gachaButton, function()
        HudSystem:toggleGacha()
    end)
    GuiUtil.applyHoverEffect(self.gachaButton)
    GuiUtil.connectButton(self.inventoryButton, function()
        HudSystem:toggleInventory()
    end)
    GuiUtil.applyHoverEffect(self.inventoryButton)
    GuiUtil.connectButton(self.rewardButton, function()
        HudSystem:toggleRewardGauge()
    end)
    GuiUtil.applyHoverEffect(self.rewardButton)
    GuiUtil.connectButton(self.skillButton, function()
        HudSystem:toggleSkillUI()
    end)
    GuiUtil.applyHoverEffect(self.skillButton)
    GuiUtil.connectButton(self.companionButton, function()
        HudSystem:toggleCompanionUI()
    end)
    GuiUtil.applyHoverEffect(self.companionButton)
    GuiUtil.connectButton(self.questButton, function()
        HudSystem:toggleQuestUI()
    end)
    GuiUtil.applyHoverEffect(self.questButton)
    GuiUtil.connectButton(self.progressButton, function()
        HudSystem:toggleProgressMap()
    end)
    GuiUtil.applyHoverEffect(self.progressButton)
    GuiUtil.connectButton(self.exchangeButton, function()
        HudSystem:toggleExchangeUI()
    end)
    GuiUtil.applyHoverEffect(self.exchangeButton)
    GuiUtil.connectButton(self.dungeonButton, function()
        HudSystem:toggleDungeonUI()
    end)
    GuiUtil.applyHoverEffect(self.dungeonButton)
    GuiUtil.connectButton(self.partyButton, function()
        HudSystem:togglePartyUI()
    end)
    GuiUtil.applyHoverEffect(self.partyButton)
    GuiUtil.connectButton(self.scoreboardButton, function()
        HudSystem:toggleScoreboard()
    end)
    GuiUtil.applyHoverEffect(self.scoreboardButton)
    GuiUtil.connectButton(self.menuButton, function()
        HudSystem:toggleMenu()
    end)
    GuiUtil.applyHoverEffect(self.menuButton)
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
    parent(self.menuButton, self.buttonFrame)

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
        HudSystem.maxCooldowns[idx] = cd
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
    if Theme and Theme.styleProgressBar then
        Theme.styleProgressBar(self.progressFrame)
        Theme.styleProgressBar(self.healthFrame)
    end
    self.skillFrame = self.skillFrame or createInstance("Frame")
    self.skillLayout = self.skillLayout or createInstance("UIListLayout")
    if self.skillLayout.Padding ~= nil then
        self.skillLayout.Padding = UDim.new(0, 4)
    end
    self.skillButtons = self.skillButtons or {}
    self.cooldownOverlays = self.cooldownOverlays or {}
    self.cooldownLabels = self.cooldownLabels or {}
    self.cooldowns = self.cooldowns or {}
    self.maxCooldowns = self.maxCooldowns or {}
    parent(self.progressFill, self.progressFrame)
    parent(self.progressText, self.progressFrame)
    parent(self.progressFrame, gui)
    parent(self.healthFill, self.healthFrame)
    parent(self.healthText, self.healthFrame)
    parent(self.healthFrame, gui)
    parent(self.skillLayout, self.skillFrame)
    parent(self.skillFrame, gui)
    self.buttonFrame = self.buttonFrame or createInstance("Frame")
    if self.buttonFrame.FindFirstChild and not self.buttonFrame:FindFirstChild("Top") then
        GuiUtil.addCrossDecor(self.buttonFrame)
    end
    self.buttonLayout = self.buttonLayout or createInstance("UIGridLayout")
    if Enum and Enum.FillDirection then
        self.buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        self.buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    if UDim2 and type(UDim2.new) == "function" then
        self.buttonLayout.CellSize = UDim2.new(0, 60, 0, 60)
        self.buttonLayout.CellPadding = UDim2.new(0, 4, 0, 4)
        self.buttonFrame.Size = UDim2.new(0.22, 0, 0.25, 0)
        self.buttonFrame.Position = UDim2.new(0.02, 0, 0.96, 0)
    end
    GuiUtil.applyResponsive(self.buttonFrame, nil, 240, 60, 400, 120)
    parent(self.buttonLayout, self.buttonFrame)
    parent(self.buttonFrame, gui)
    self.skillLayout = self.skillLayout or createInstance("UIListLayout")
    if Enum and Enum.FillDirection then
        self.skillLayout.FillDirection = Enum.FillDirection.Horizontal
        self.skillLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end
    if self.skillLayout.Padding ~= nil then
        self.skillLayout.Padding = UDim.new(0, 4)
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
    if Theme and Theme.getHealthColor then
        local color = Theme.getHealthColor(hpRatio)
        local ok = pcall(function()
            self.healthFill.BackgroundColor3 = color
        end)
        if not ok and type(self.healthFill)=="table" then
            self.healthFill.BackgroundColor3 = color
        end
    end
    if UDim2 and type(UDim2.new)=="function" then
        self.healthFill.Size = UDim2.new(hpRatio, 0, 1, 0)
    else
        self.healthFill.FillRatio = hpRatio
    end

    self.autoButton = self.autoButton or createInstance("TextButton")
    parent(self.autoButton, self.buttonFrame)
    local state = self.autoEnabled and "ON" or "OFF"
    self.autoButton.Text = "Auto: " .. state

    self.attackButton = self.attackButton or createInstance("TextButton")
    parent(self.attackButton, self.buttonFrame)
    self.attackButton.Text = "Attack"
    self.attackButton.Active = not self.autoEnabled

    self.gachaButton = self.gachaButton or createInstance("ImageButton")
    parent(self.gachaButton, self.buttonFrame)
    self.gachaButton.Image = menuIcons.Gacha

    self.inventoryButton = self.inventoryButton or createInstance("ImageButton")
    parent(self.inventoryButton, self.buttonFrame)
    self.inventoryButton.Image = menuIcons.Inventory

    self.rewardButton = self.rewardButton or createInstance("ImageButton")
    parent(self.rewardButton, self.buttonFrame)
    self.rewardButton.Image = menuIcons.Reward

    self.skillButton = self.skillButton or createInstance("ImageButton")
    parent(self.skillButton, self.buttonFrame)
    self.skillButton.Image = menuIcons.Skills

    self.companionButton = self.companionButton or createInstance("ImageButton")
    parent(self.companionButton, self.buttonFrame)
    self.companionButton.Image = menuIcons.Companions

    self.questButton = self.questButton or createInstance("ImageButton")
    parent(self.questButton, self.buttonFrame)
    self.questButton.Image = menuIcons.Quests

    self.progressButton = self.progressButton or createInstance("ImageButton")
    parent(self.progressButton, self.buttonFrame)
    self.progressButton.Image = menuIcons.Map

    self.exchangeButton = self.exchangeButton or createInstance("ImageButton")
    parent(self.exchangeButton, self.buttonFrame)
    self.exchangeButton.Image = menuIcons.Exchange

    self.dungeonButton = self.dungeonButton or createInstance("ImageButton")
    parent(self.dungeonButton, self.buttonFrame)
    self.dungeonButton.Image = menuIcons.Dungeons

    self.partyButton = self.partyButton or createInstance("ImageButton")
    parent(self.partyButton, self.buttonFrame)
    self.partyButton.Image = menuIcons.Party

    self.scoreboardButton = self.scoreboardButton or createInstance("ImageButton")
    parent(self.scoreboardButton, self.buttonFrame)
    self.scoreboardButton.Image = menuIcons.Scoreboard

    self.menuButton = self.menuButton or createInstance("ImageButton")
    parent(self.menuButton, self.buttonFrame)
    self.menuButton.Image = menuIcons.Menu

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
            GuiUtil.addCrossDecor(btn)
            if Instance and typeof and typeof(Instance.new)=="function" then
                local aspect = Instance.new("UIAspectRatioConstraint")
                aspect.AspectRatio = 1
                aspect.Parent = btn
            end
            btn.LayoutOrder = i
            local pressStart = 0
            if btn.MouseButton1Down then
                btn.MouseButton1Down:Connect(function()
                    pressStart = os.clock()
                end)
            end
            if btn.MouseButton1Up then
                btn.MouseButton1Up:Connect(function()
                    local duration = os.clock() - pressStart
                    if duration > 0.5 then
                        local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
                        MenuUISystem:openTab("Skills")
                    else
                        NetworkSystem:fireServer("SkillRequest", i)
                    end
                end)
            else
                GuiUtil.connectButton(btn, function()
                    NetworkSystem:fireServer("SkillRequest", i)
                end)
            end
            if btn.MouseButton2Click then
                btn.MouseButton2Click:Connect(function()
                    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
                    MenuUISystem:openTab("Skills")
                end)
            end
            GuiUtil.applyHoverEffect(btn)
            parent(btn, self.skillFrame)
            self.skillButtons[i] = btn
            -- display the key number in the corner for quick reference
            local keyLabel = createInstance("TextLabel")
            keyLabel.Name = "Key" .. i
            keyLabel.BackgroundTransparency = 1
            keyLabel.TextScaled = true
            keyLabel.Text = tostring(i)
            if UDim2 and type(UDim2.new)=="function" then
                keyLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
                keyLabel.Position = UDim2.new(0.7, 0, 0.7, 0)
            end
            if keyLabel.ZIndex ~= nil then
                keyLabel.ZIndex = 2
            else
                keyLabel.zIndex = 2
            end
            parent(keyLabel, btn)
            -- hint that holding the button opens the skill menu
            local hint = createInstance("TextLabel")
            hint.Name = "Hint" .. i
            hint.BackgroundTransparency = 1
            hint.TextScaled = true
            hint.Text = "↗"
            if UDim2 and type(UDim2.new)=="function" then
                hint.Size = UDim2.new(0.3,0,0.3,0)
                hint.Position = UDim2.new(0.7,0,0,0)
            end
            if hint.ZIndex ~= nil then
                hint.ZIndex = 2
            else
                hint.zIndex = 2
            end
            parent(hint, btn)
            local overlay = createInstance("Frame")
            overlay.BackgroundTransparency = 0.4
            overlay.BackgroundColor3 = Theme and Theme.colors and Theme.colors.cooldownOverlay or (Color3 and Color3.fromRGB and Color3.fromRGB(0,0,0) or {r=0,g=0,b=0})
            overlay.BorderSizePixel = 0
            if UDim2 and type(UDim2.new)=="function" then
                overlay.Size = UDim2.new(1,0,1,0)
            end
            if overlay.ZIndex ~= nil then
                overlay.ZIndex = 1
            else
                overlay.zIndex = 1
            end
            parent(overlay, btn)
            self.cooldownOverlays[i] = overlay
        end
        btn.Image = skill.image or ""
        self.maxCooldowns[i] = self.maxCooldowns[i] or (skill.cooldown or 1)
        local cdLabel = self.cooldownLabels[i]
        if not cdLabel then
            cdLabel = createInstance("TextLabel")
            cdLabel.BackgroundTransparency = 0.5
            cdLabel.Size = UDim2.new(1,0,1,0)
            cdLabel.TextScaled = true
            cdLabel.TextColor3 = Theme and Theme.colors.labelText or Color3.new(1,1,1)
            cdLabel.BackgroundColor3 = Color3 and Color3.fromRGB and Color3.fromRGB(0,0,0) or {r=0,g=0,b=0}
            cdLabel.TextXAlignment = Enum and Enum.TextXAlignment.Center or cdLabel.TextXAlignment
            cdLabel.TextYAlignment = Enum and Enum.TextYAlignment.Center or cdLabel.TextYAlignment
            parent(cdLabel, btn)
            self.cooldownLabels[i] = cdLabel
        end
        if cdLabel.ZIndex ~= nil then
            cdLabel.ZIndex = 2
        else
            cdLabel.zIndex = 2
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
        self.progressFrame.Position = UDim2.new(0.5, -200, 0.02, 0)
        self.progressFrame.Size = UDim2.new(0.4, 0, 0, 25)
        local fillColor = Theme and Theme.colors and Theme.colors.progressBar or Color3.fromRGB(80, 120, 220)
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
            self.progressFill.color = Theme and Theme.colors and Theme.colors.progressBar
        end
        self.progressFill.FillRatio = ratio
    end

    for i, cd in pairs(self.cooldowns) do
        if cd > 0 then
            self.cooldowns[i] = math.max(0, cd - dt)
        end
        local overlay = self.cooldownOverlays[i]
        local maxCd = self.maxCooldowns[i] or cd
        if overlay and UDim2 and type(UDim2.new)=="function" then
            local ratio = (self.cooldowns[i] or 0) / math.max(maxCd, 1)
            overlay.Size = UDim2.new(1,0,ratio,0)
            overlay.Position = UDim2.new(0,0,1-ratio,0)
            overlay.Visible = self.cooldowns[i] > 0
        elseif overlay then
            overlay.Visible = self.cooldowns[i] > 0
        end
        if self.cooldownLabels[i] then
            if self.cooldowns[i] > 0 then
                self.cooldownLabels[i].Text = tostring(math.ceil(self.cooldowns[i]))
                self.cooldownLabels[i].Visible = true
            else
                self.cooldownLabels[i].Visible = false
                self.cooldownLabels[i].Text = ""
            end
        end
        if self.skillButtons[i] then
            GuiUtil.highlightButton(self.skillButtons[i], self.cooldowns[i] <= 0)
        end
    end

    if UDim2 and type(UDim2.new)=="function" then
        self.levelLabel.Position = UDim2.new(0.02, 0, 0.02, 0)
        self.currencyLabel.Position = UDim2.new(0.02, 0, 0.06, 0)
        self.buttonFrame.Size = UDim2.new(0.22, 0, 0.25, 0)
        self.buttonFrame.Position = UDim2.new(0.02, 0, 0.96, 0)
        self.buttonFrame.AnchorPoint = Vector2.new(0, 1)
        GuiUtil.applyResponsive(self.buttonFrame, nil, 240, 60, 400, 120)
        self.healthFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
        self.healthFrame.Size = UDim2.new(0.25, 0, 0.04, 0)
        -- Position skill buttons near the bottom-right similar to modern action RPGs
        -- https://create.roblox.com/docs/reference/engine/classes/UDim2
        self.skillFrame.Position = UDim2.new(1, -262, 1, -70)
        self.skillFrame.Size = UDim2.new(0, 252, 0, 60)
        self.skillFrame.AnchorPoint = Vector2.new(1, 1)
        self.progressFrame.Position = UDim2.new(0.5, -200, 0.02, 0)
        self.progressFrame.Size = UDim2.new(0.4, 0, 0, 25)
        self.progressFrame.AnchorPoint = Vector2.new(0.5, 0)
    end
end

function HudSystem:toggleAutoBattle()
    NetworkSystem:fireServer("AutoBattleToggle")
end

function HudSystem:manualAttack()
    if self.autoEnabled then
        return
    end
    local PlayerInputSystem = require(script.Parent:WaitForChild("PlayerInputSystem"))
    PlayerInputSystem:manualAttack()
end

function HudSystem:toggleGacha()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Gacha")
end

function HudSystem:toggleInventory()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Inventory")
end

function HudSystem:toggleRewardGauge()
    local RewardGaugeUISystem = require(script.Parent:WaitForChild("RewardGaugeUISystem"))
    RewardGaugeUISystem:toggle()
end

function HudSystem:toggleSkillUI()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Skills")
end

function HudSystem:toggleCompanionUI()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Companions")
end

function HudSystem:toggleQuestUI()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Quests")
end

function HudSystem:toggleProgressMap()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Progress")
end

function HudSystem:toggleExchangeUI()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Exchange")
end

function HudSystem:toggleDungeonUI()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:openTab("Dungeons")
end

function HudSystem:togglePartyUI()
    local PartyUISystem = require(script.Parent:WaitForChild("PartyUISystem"))
    PartyUISystem:toggle()
end

function HudSystem:toggleScoreboard()
    local ScoreboardUISystem = require(script.Parent:WaitForChild("ScoreboardUISystem"))
    ScoreboardUISystem:toggle()
end

function HudSystem:toggleMenu()
    local MenuUISystem = require(script.Parent:WaitForChild("MenuUISystem"))
    MenuUISystem:toggle()
end

return HudSystem
