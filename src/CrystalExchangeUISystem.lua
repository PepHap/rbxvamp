-- CrystalExchangeUISystem.lua
-- UI for purchasing gacha tickets and upgrade currency with crystals

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local CrystalExchangeUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    exchangeSystem = nil,
    window = nil,
    buttons = {},
}

local CrystalExchangeSystem = require(script.Parent:WaitForChild("CrystalExchangeSystem"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if CrystalExchangeUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if CrystalExchangeUI.gui and (not CrystalExchangeUI.useRobloxObjects or CrystalExchangeUI.gui.Parent) then
        return CrystalExchangeUI.gui
    end
    local pgui
    if CrystalExchangeUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("CrystalExchangeUI")
            if existing then
                CrystalExchangeUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "CrystalExchangeUI"
    if gui.Enabled ~= nil then gui.Enabled = true end
    CrystalExchangeUI.gui = gui
    if CrystalExchangeUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function CrystalExchangeUI:start(exchangeSys)
    self.exchangeSystem = exchangeSys or self.exchangeSystem or CrystalExchangeSystem
    local gui = ensureGui()
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        return
    end

    self.window = GuiUtil.createWindow("CrystalExchangeWindow")
    parent(self.window, gui)
    GuiUtil.makeFullScreen(self.window)

    local actions = {
        {"Buy Skill Ticket", function() self:buyTicket("skill") end},
        {"Buy Companion Ticket", function() self:buyTicket("companion") end},
        {"Buy Equipment Ticket", function() self:buyTicket("equipment") end},
        {"Buy Gold", function() self:buyCurrency("gold") end},
    }
    self.buttons = {}
    for i, info in ipairs(actions) do
        local btn = createInstance("TextButton")
        btn.Text = info[1]
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(0,5,0,(i-1)*30)
            btn.Size = UDim2.new(1,-10,0,25)
        end
        parent(btn, self.window)
        GuiUtil.connectButton(btn, info[2])
        table.insert(self.buttons, btn)
    end

    self:setVisible(self.visible)
end

function CrystalExchangeUI:buyTicket(kind)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("ExchangeRequest", "ticket", kind, 1)
        return true
    end
    if not self.exchangeSystem then return false end
    return self.exchangeSystem:buyTickets(kind, 1)
end

function CrystalExchangeUI:buyCurrency(kind)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("ExchangeRequest", "currency", kind, 1)
        return true
    end
    if not self.exchangeSystem then return false end
    return self.exchangeSystem:buyCurrency(kind, 1)
end

function CrystalExchangeUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function CrystalExchangeUI:toggle()
    if not self.gui then
        self:start(self.exchangeSystem)
    end
    self:setVisible(not self.visible)
end

return CrystalExchangeUI

