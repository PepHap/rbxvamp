local UISystem = {
    ---When true and running inside Roblox, real Instances will be created.
    useRobloxObjects = false,

    ---ScreenGui container for all UI elements created by this system.
    gui = nil,

    ---Label displaying the current reward gauge value.
    gaugeLabel = nil,

    ---Temporary reward option buttons
    rewardButtons = nil,

    ---Label showing the selected reward
    selectionLabel = nil,

    ---Label displaying gacha results
    gachaLabel = nil,
}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

-- Helper to create an Instance when available or fall back to a table
local function createInstance(className)
    if UISystem.useRobloxObjects and typeof ~= nil and Instance ~= nil and type(Instance.new) == "function" then
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

-- Parent ``child`` to ``parent`` in both real Roblox and table form
local function parent(child, parentObj)
    if child == nil or parentObj == nil then
        return
    end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

-- Lazily creates and returns the ScreenGui
local function ensureGui()
    if UISystem.gui then
        return UISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "UISystemGui"
    if type(gui) == "table" then
        gui.children = {}
    end
    UISystem.gui = gui
    if UISystem.useRobloxObjects then
        local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))

---Displays reward options from the RewardGaugeSystem if available.
-- Prints each option to the console.
-- @return table|nil list of options
function UISystem:showRewardOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then
        return nil
    end

    local gui = ensureGui()
    self.rewardButtons = {}
    gui.rewardButtons = self.rewardButtons

    for i, opt in ipairs(opts) do
        local btn = createInstance("TextButton")
        btn.Text = ("%d) %s (%s)"):format(i, opt.item.name, opt.slot)
        parent(btn, gui)
        table.insert(self.rewardButtons, btn)
    end

    return opts
end

---Selects a reward option by index and prints the result.
-- @param index number option index
-- @return table|nil chosen reward
function UISystem:selectReward(index)
    local chosen = RewardGaugeSystem:choose(index)

    local gui = ensureGui()
    self.selectionLabel = self.selectionLabel or createInstance("TextLabel")
    parent(self.selectionLabel, gui)
    gui.selectionLabel = self.selectionLabel

    if chosen then
        self.selectionLabel.Text = ("Selected %s for %s"):format(chosen.item.name, chosen.slot)
    else
        self.selectionLabel.Text = "Invalid reward selection"
    end

    self.rewardButtons = nil

    return chosen
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
end

---Rolls a skill through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled skill
function UISystem:rollSkill()
    local result = GachaSystem:rollSkill()
    self:displayGachaResult(result)
    return result
end

---Rolls a companion through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled companion
function UISystem:rollCompanion()
    local result = GachaSystem:rollCompanion()
    self:displayGachaResult(result)
    return result
end

---Rolls equipment for the specified slot and displays the outcome.
-- @param slot string equipment slot
-- @return table|nil the rolled equipment
function UISystem:rollEquipment(slot)
    local result = GachaSystem:rollEquipment(slot)
    self:displayGachaResult(result)
    return result
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
    parent(btn, gui)
    return btn
end

---Creates a button representing a skill choice.
function UISystem:showSkillChoice(skill)
    local gui = ensureGui()
    local btn = createInstance("TextButton")
    btn.Text = skill.name
    parent(btn, gui)
    return btn
end

---Creates a button representing a companion choice.
function UISystem:showCompanionChoice(companion)
    local gui = ensureGui()
    local btn = createInstance("TextButton")
    btn.Text = companion.name
    parent(btn, gui)
    return btn
end

return UISystem
