local UISystem = {
    ---When true and running inside Roblox, real Instances will be created.
    useRobloxObjects = false,

    ---ScreenGui container for all UI elements created by this system.
    gui = nil,

    ---Label displaying the current reward gauge value.
    gaugeLabel = nil,
}

-- Helper to create an Instance when available or fall back to a table
local function createInstance(className)
    if UISystem.useRobloxObjects and Instance ~= nil and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
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
    gui.children = {}
    UISystem.gui = gui
    if UISystem.useRobloxObjects and game ~= nil and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

local RewardGaugeSystem = require("src.RewardGaugeSystem")
local GachaSystem = require("src.GachaSystem")

---Displays reward options from the RewardGaugeSystem if available.
-- Prints each option to the console.
-- @return table|nil list of options
function UISystem:showRewardOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then
        return nil
    end

    local gui = ensureGui()
    gui.rewardButtons = {}

    for i, opt in ipairs(opts) do
        local btn = createInstance("TextButton")
        btn.Text = ("%d) %s (%s)"):format(i, opt.item.name, opt.slot)
        btn.OptionIndex = i
        parent(btn, gui)
        table.insert(gui.rewardButtons, btn)
    end

    return opts
end

---Selects a reward option by index and prints the result.
-- @param index number option index
-- @return table|nil chosen reward
function UISystem:selectReward(index)
    local chosen = RewardGaugeSystem:choose(index)

    local gui = ensureGui()
    gui.selectionLabel = gui.selectionLabel or createInstance("TextLabel")
    parent(gui.selectionLabel, gui)

    if chosen then
        gui.selectionLabel.Text = ("Selected %s for %s"):format(chosen.item.name, chosen.slot)
    else
        gui.selectionLabel.Text = "Invalid reward selection"
    end

    gui.rewardButtons = nil

    return chosen
end

---Displays the result of a gacha roll.
-- @param result table|nil reward returned from GachaSystem
function UISystem:displayGachaResult(result)
    local gui = ensureGui()
    gui.gachaLabel = gui.gachaLabel or createInstance("TextLabel")
    parent(gui.gachaLabel, gui)

    if not result then
        gui.gachaLabel.Text = "Gacha: no reward"
        return
    end

    local extra = result.slot and (" - " .. result.slot) or ""
    local rarity = result.rarity or "?"
    gui.gachaLabel.Text = ("Gacha: %s [%s]%s"):format(result.name, rarity, extra)
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
