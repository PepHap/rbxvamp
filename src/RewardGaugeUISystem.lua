-- RewardGaugeUISystem.lua
-- Displays reward gauge progress and allows selecting options

local RewardGaugeUISystem = {
    useRobloxObjects = false,
    gui = nil,
    gaugeLabel = nil,
    optionButtons = nil,
    visible = false,
    window = nil,
}

local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function applyRarityColor(obj, rarity)
    if not obj or not Theme or not Theme.rarityColors then return end
    local col = Theme.rarityColors[rarity]
    if not col then return end
    local ok = pcall(function() obj.TextColor3 = col end)
    if not ok and type(obj) == "table" then
        obj.TextColor3 = col
    end
end

local function createInstance(className)
    if RewardGaugeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if RewardGaugeUISystem.gui then return RewardGaugeUISystem.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "RewardGaugeUI"
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    RewardGaugeUISystem.gui = gui
    if RewardGaugeUISystem.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function RewardGaugeUISystem:start()
    local gui = ensureGui()

    -- simple frame; image removed to keep repository text only
    self.window = GuiUtil.createWindow("RewardWindow")
    parent(self.window, gui)

    self.gaugeLabel = createInstance("TextLabel")
    parent(self.gaugeLabel, self.window)
    self:update()
    self:setVisible(self.visible)
end

function RewardGaugeUISystem:update()
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.gaugeLabel = self.gaugeLabel or createInstance("TextLabel")
    parent(self.gaugeLabel, parentGui)
    local segments = 10
    local filled = math.floor((RewardGaugeSystem.gauge / RewardGaugeSystem.maxGauge) * segments)
    local bar = string.rep("●", filled) .. string.rep("○", segments - filled)
    self.gaugeLabel.Text = string.format("Gauge: %s %d/%d", bar, RewardGaugeSystem.gauge, RewardGaugeSystem.maxGauge)
end

function RewardGaugeUISystem:showOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then return nil end
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.optionButtons = {}
    parentGui.optionButtons = self.optionButtons
    for i, opt in ipairs(opts) do
        local btn = createInstance("TextButton")
        btn.Text = string.format("%d) %s (%s)", i, opt.item.name, opt.slot)
        applyRarityColor(btn, opt.item.rarity)
        GuiUtil.connectButton(btn, function()
            RewardGaugeUISystem:choose(i)
        end)
        parent(btn, parentGui)
        table.insert(self.optionButtons, btn)
    end
    return opts
end

function RewardGaugeUISystem:choose(index)
    local chosen = RewardGaugeSystem:choose(index)
    self.optionButtons = nil
    self:update()
    return chosen
end

function RewardGaugeUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function RewardGaugeUISystem:toggle()
    self:setVisible(not self.visible)
end

return RewardGaugeUISystem
