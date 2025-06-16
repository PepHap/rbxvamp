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

local function createInstance(className)
    if RewardGaugeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then return end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if RewardGaugeUISystem.gui then return RewardGaugeUISystem.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "RewardGaugeUI"
    RewardGaugeUISystem.gui = gui
    if RewardGaugeUISystem.useRobloxObjects then
        local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
        local pgui = GuiUtil.getPlayerGui()
        if pgui then
            gui.Parent = pgui
        end
    end
    return gui
end

function RewardGaugeUISystem:start()
    local gui = ensureGui()
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

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
    self.gaugeLabel.Text = string.format("Gauge: %d/%d", RewardGaugeSystem.gauge, RewardGaugeSystem.maxGauge)
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
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                RewardGaugeUISystem:choose(i)
            end)
        else
            btn.onClick = function()
                RewardGaugeUISystem:choose(i)
            end
        end
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
    if parentGui.Enabled ~= nil then
        parentGui.Enabled = self.visible
    else
        parentGui.Visible = self.visible
    end
end

function RewardGaugeUISystem:toggle()
    self:setVisible(not self.visible)
end

return RewardGaugeUISystem
