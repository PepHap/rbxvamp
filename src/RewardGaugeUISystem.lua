-- RewardGaugeUISystem.lua
-- Displays reward gauge progress and allows selecting options
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("RewardGaugeUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local RewardGaugeUISystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    gaugeLabel = nil,
    optionButtons = nil,
    layout = nil,
    visible = false,
    window = nil,
}

local RewardGaugeSystem = require(script.Parent:WaitForChild("ClientRewardGaugeSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
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
    if RewardGaugeUISystem.gui and (not RewardGaugeUISystem.useRobloxObjects or RewardGaugeUISystem.gui.Parent) then
        return RewardGaugeUISystem.gui
    end
    local pgui
    if RewardGaugeUISystem.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("RewardGaugeUI")
            if existing then
                RewardGaugeUISystem.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "RewardGaugeUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    RewardGaugeUISystem.gui = gui
    if RewardGaugeUISystem.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

local function clearChildren(container)
    if typeof and typeof(container) == "Instance" and container.GetChildren then
        for _, child in ipairs(container:GetChildren()) do
            if child.Destroy then
                child:Destroy()
            end
        end
    elseif type(container) == "table" then
        container.children = {}
    end
end

function RewardGaugeUISystem:start()
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
    else
        -- simple frame; image removed to keep repository text only
        self.window = GuiUtil.createWindow("RewardWindow")
        if UDim2 and type(UDim2.new)=="function" then
            self.window.AnchorPoint = Vector2.new(0, 0)
            self.window.Position = UDim2.new(0, 0, 0, 0)
            self.window.Size = UDim2.new(1, 0, 1, 0)
        end
        parent(self.window, gui)
        
        self.gaugeLabel = createInstance("TextLabel")
        if UDim2 and type(UDim2.new)=="function" then
            self.gaugeLabel.Position = UDim2.new(0, 5, 0, 5)
            self.gaugeLabel.Size = UDim2.new(1, -10, 0, 20)
        end
        parent(self.gaugeLabel, self.window)

        self.layout = createInstance("UIListLayout")
        if UDim and type(UDim.new) == "function" then
            self.layout.Padding = UDim.new(0, 5)
        end
        if Enum and Enum.FillDirection then
            self.layout.FillDirection = Enum.FillDirection.Vertical
            self.layout.SortOrder = Enum.SortOrder.LayoutOrder
            if self.layout.HorizontalAlignment ~= nil then
                self.layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
            if self.layout.VerticalAlignment ~= nil then
                self.layout.VerticalAlignment = Enum.VerticalAlignment.Center
            end
        end
        parent(self.layout, self.window)
    end
    self:update()
    self:setVisible(self.visible)

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("GaugeUpdate", function(g, maxG)
            RewardGaugeSystem.gauge = g
            RewardGaugeSystem.maxGauge = maxG
            RewardGaugeUISystem:update()
        end)
        NetworkSystem:onClientEvent("GaugeOptions", function(opts)
            RewardGaugeSystem.options = opts
            if opts then
                RewardGaugeUISystem:showOptions()
            else
                if RewardGaugeUISystem.optionButtons then
                    for _, btn in ipairs(RewardGaugeUISystem.optionButtons) do
                        if btn.Destroy then
                            btn:Destroy()
                        end
                    end
                end
                RewardGaugeUISystem.optionButtons = nil
                RewardGaugeUISystem:update()
            end
        end)
        NetworkSystem:onClientEvent("RewardResult", function()
            RewardGaugeUISystem:update()
        end)
    end
end

function RewardGaugeUISystem:update()
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.gaugeLabel = self.gaugeLabel or createInstance("TextLabel")
    parent(self.gaugeLabel, parentGui)
    local segments = 10
    local max = RewardGaugeSystem.maxGauge
    if not max or max <= 0 then
        max = 1
    end
    local ratio = RewardGaugeSystem.gauge / max
    local filled = math.floor(ratio * segments)
    local bar = string.rep("●", filled) .. string.rep("○", segments - filled)
    self.gaugeLabel.Text = string.format("Gauge: %s %d/%d", bar, RewardGaugeSystem.gauge, max)
end

function RewardGaugeUISystem:showOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then return nil end
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.layout = self.layout or createInstance("UIListLayout")
    if not self.layout.Parent then
        if UDim and type(UDim.new) == "function" then
            self.layout.Padding = UDim.new(0, 5)
        end
        if Enum and Enum.FillDirection then
            self.layout.FillDirection = Enum.FillDirection.Vertical
            self.layout.SortOrder = Enum.SortOrder.LayoutOrder
            if self.layout.HorizontalAlignment ~= nil then
                self.layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
            if self.layout.VerticalAlignment ~= nil then
                self.layout.VerticalAlignment = Enum.VerticalAlignment.Center
            end
        end
        parent(self.layout, parentGui)
    end
    if self.optionButtons then
        for _, btn in ipairs(self.optionButtons) do
            if btn.Destroy then
                btn:Destroy()
            end
        end
    end
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
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("RewardChoice", index)
    end
    if self.optionButtons then
        for _, btn in ipairs(self.optionButtons) do
            if btn.Destroy then
                btn:Destroy()
            end
        end
    end
    self.optionButtons = nil
    self:update()
end

function RewardGaugeUISystem:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function RewardGaugeUISystem:toggle()
    if not self.gui then
        self:start()
    end
    self:setVisible(not self.visible)
end

return RewardGaugeUISystem
