-- CrystalExchangeUISystem.lua
-- UI for buying gacha tickets or upgrade currency with crystals

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local UI = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    visible = false,
    exchangeSystem = nil,
    crystalLabel = nil,
    ticketButtons = nil,
    currencyButtons = nil,
    window = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local CrystalExchangeSystem = require(script.Parent:WaitForChild("CrystalExchangeSystem"))
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if UI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
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
    if not child or not parentObj then return end
    if typeof and typeof(child)=="Instance" and typeof(parentObj)=="Instance" then
        child.Parent = parentObj
    else
        child.Parent = parentObj
    end
    if type(parentObj)=="table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if UI.gui then return UI.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "CrystalExchangeUI"
    if gui.Enabled ~= nil then gui.Enabled = true end
    UI.gui = gui
    if UI.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then gui.Parent = pgui end
    end
    return gui
end

local ticketOrder = {"skill","companion","equipment"}
local currencyOrder = {"gold","ore","ether","crystal"}

function UI:start(sys)
    self.exchangeSystem = sys or self.exchangeSystem or CrystalExchangeSystem
    local gui = ensureGui()

    self.window = GuiUtil.createWindow("CrystalExchangeWindow")
    parent(self.window, gui)

    self.crystalLabel = createInstance("TextLabel")
    parent(self.crystalLabel, self.window)

    self.ticketButtons = {}
    for _, kind in ipairs(ticketOrder) do
        if self.exchangeSystem.ticketPrices[kind] then
            local btn = createInstance("TextButton")
            btn.Text = "Buy " .. kind .. " ticket"
            GuiUtil.connectButton(btn, function()
                UI:buyTicket(kind)
            end)
            parent(btn, self.window)
            table.insert(self.ticketButtons, btn)
        end
    end

    self.currencyButtons = {}
    for _, kind in ipairs(currencyOrder) do
        if self.exchangeSystem.currencyPrices[kind] then
            local btn = createInstance("TextButton")
            btn.Text = "Buy " .. kind
            GuiUtil.connectButton(btn, function()
                UI:buyCurrency(kind)
            end)
            parent(btn, self.window)
            table.insert(self.currencyButtons, btn)
        end
    end

    self:update()
    self:setVisible(self.visible)
end

function UI:update()
    local gui = ensureGui()
    local parentGui = self.window or gui
    self.crystalLabel = self.crystalLabel or createInstance("TextLabel")
    parent(self.crystalLabel, parentGui)
    self.crystalLabel.Text = "Crystals: " .. tostring(GachaSystem.crystals or 0)
end

function UI:buyTicket(kind)
    if self.exchangeSystem:buyTickets(kind, 1) then
        self:update()
        return true
    end
    return false
end

function UI:buyCurrency(kind)
    if self.exchangeSystem:buyCurrency(kind, 1) then
        self:update()
        return true
    end
    return false
end

function UI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function UI:toggle()
    if not self.gui then self:start(self.exchangeSystem) end
    self:setVisible(not self.visible)
end

return UI

