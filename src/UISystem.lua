local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("UISystem should only be required on the client", 2)
end
local UISystem = {
    ---When true and running inside Roblox, real Instances will be created.
    useRobloxObjects = EnvironmentUtil.detectRoblox(),

    ---ScreenGui container for all UI elements created by this system.
    gui = nil,

    ---Label displaying the current reward gauge value.
    gaugeLabel = nil,

    ---Temporary reward option buttons
    rewardButtons = nil,

    ---Window container for reward options
    optionsWindow = nil,

    ---Label showing the selected reward
    selectionLabel = nil,

    ---Label displaying gacha results
    gachaLabel = nil,
}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

-- Helper to create an Instance when available or fall back to a table
local function createInstance(className)
    if UISystem.useRobloxObjects and typeof ~= nil and Instance ~= nil and type(Instance.new) == "function" then
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

-- Parent ``child`` to ``parent`` in both real Roblox and table form
local function parent(child, parentObj)
    GuiUtil.parent(child, parentObj)
end

-- Lazily creates and returns the ScreenGui
local function ensureGui()
    if UISystem.gui and (not UISystem.useRobloxObjects or UISystem.gui.Parent) then
        return UISystem.gui
    end
    local pgui
    if UISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("UISystemGui")
            if existing then
                UISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "UISystemGui"
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    if type(gui) == "table" then
        gui.children = {}
    end
    UISystem.gui = gui
    if UISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))

if NetworkSystem and NetworkSystem.onClientEvent then
    NetworkSystem:onClientEvent("GachaResult", function(_, reward)
        UISystem:displayGachaResult(reward)
    end)
end

---Displays reward options from the RewardGaugeSystem if available.
-- Prints each option to the console.
-- @return table|nil list of options
function UISystem:showRewardOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then
        return nil
    end

    local gui = ensureGui()
    if not self.optionsWindow then
        self.optionsWindow = GuiUtil.createWindow("RewardOptions")
        if UDim2 and type(UDim2.new)=="function" then
            self.optionsWindow.Size = UDim2.new(1, 0, 1, 0)
            self.optionsWindow.Position = UDim2.new(0, 0, 0, 0)
            self.optionsWindow.AnchorPoint = Vector2.new(0, 0)
            GuiUtil.clampToScreen(self.optionsWindow)
        end
        parent(self.optionsWindow, gui)
        local closeBtn = createInstance("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Text = "X"
        if UDim2 and type(UDim2.new)=="function" then
            closeBtn.Size = UDim2.new(0,20,0,20)
            closeBtn.Position = UDim2.new(1,-25,0,5)
        end
        parent(closeBtn, self.optionsWindow)
        GuiUtil.connectButton(closeBtn, function()
            UISystem.optionsWindow.Visible = false
        end)
    else
        GuiUtil.setVisible(self.optionsWindow, true)
    end

    self.rewardButtons = {}
    self.optionsWindow.rewardButtons = self.rewardButtons

    for i, opt in ipairs(opts) do
        local btn = createInstance("TextButton")
        btn.Text = ("%d) %s (%s)"):format(i, opt.item.name, opt.slot)
        if Theme and Theme.rarityColors and Theme.rarityColors[opt.item.rarity] then
            btn.TextColor3 = Theme.rarityColors[opt.item.rarity]
        end
        parent(btn, self.optionsWindow)
        table.insert(self.rewardButtons, btn)
    end

    return opts
end

---Selects a reward option by index and notifies the server.
-- @param index number option index
function UISystem:selectReward(index)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("RewardChoice", index)
    end
    local gui = ensureGui()
    self.selectionLabel = self.selectionLabel or createInstance("TextLabel")
    parent(self.selectionLabel, gui)
    gui.selectionLabel = self.selectionLabel
    self.selectionLabel.Text = "Reward choice sent"

    self.rewardButtons = nil
    if self.optionsWindow then
        GuiUtil.setVisible(self.optionsWindow, false)
    end

    return nil
end

---Displays the result of a gacha roll.
-- @param result table|nil reward returned from GachaSystem
function UISystem:displayGachaResult(result)
    local gui = ensureGui()
    self.gachaLabel = self.gachaLabel or createInstance("TextLabel")
    parent(self.gachaLabel, gui)
    gui.gachaLabel = self.gachaLabel

    if not result then
        self.gachaLabel.Text = "Gacha: no reward"
        return
    end

    local extra = result.slot and (" - " .. result.slot) or ""
    local rarity = result.rarity or "?"
    self.gachaLabel.Text = ("Gacha: %s [%s]%s"):format(result.name, rarity, extra)
    if Theme and Theme.rarityColors and Theme.rarityColors[rarity] then
        self.gachaLabel.TextColor3 = Theme.rarityColors[rarity]
    end
end

---Rolls a skill through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled skill
function UISystem:rollSkill()
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "skill")
    end
end

---Rolls a companion through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled companion
function UISystem:rollCompanion()
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "companion")
    end
end

---Rolls equipment for the specified slot and displays the outcome.
-- @param slot string equipment slot
-- @return table|nil the rolled equipment
function UISystem:rollEquipment(slot)
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "equipment", slot)
    end
end

---Displays the current reward gauge value in a TextLabel.
function UISystem:displayRewardGauge()
    local gui = ensureGui()
    self.gaugeLabel = self.gaugeLabel or createInstance("TextLabel")
    parent(self.gaugeLabel, gui)
    self.gaugeLabel.Text = string.format("Gauge: %d/%d", RewardGaugeSystem.gauge, RewardGaugeSystem.maxGauge)
    return self.gaugeLabel
end

---Creates a button representing an item choice.
-- @param item table item data
function UISystem:showItemChoice(item)
    local gui = ensureGui()
    local btn = createInstance("TextButton")
    btn.Text = item.name
    if Theme and Theme.rarityColors and Theme.rarityColors[item.rarity] then
        btn.TextColor3 = Theme.rarityColors[item.rarity]
    end
    parent(btn, gui)
    return btn
end

---Creates a button representing a skill choice.
function UISystem:showSkillChoice(skill)
    local gui = ensureGui()
    local btn = createInstance("TextButton")
    btn.Text = skill.name
    if Theme and Theme.rarityColors and Theme.rarityColors[skill.rarity] then
        btn.TextColor3 = Theme.rarityColors[skill.rarity]
    end
    parent(btn, gui)
    return btn
end

---Creates a button representing a companion choice.
function UISystem:showCompanionChoice(companion)
    local gui = ensureGui()
    local btn = createInstance("TextButton")
    btn.Text = companion.name
    if Theme and Theme.rarityColors and Theme.rarityColors[companion.rarity] then
        btn.TextColor3 = Theme.rarityColors[companion.rarity]
    end
    parent(btn, gui)
    return btn
end

return UISystem
