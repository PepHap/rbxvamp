-- AdminConsoleSystem.lua
-- Simple console interface for admins to issue commands during gameplay

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local AdminConsole = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    visible = false,
    commandBox = nil,
    outputLabel = nil,
    adminIds = {},
    gameManager = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if AdminConsole.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "TextButton" then Theme.styleButton(inst)
            elseif className == "TextBox" then Theme.styleInput(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "TextBox" then Theme.styleInput(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function ensureGui()
    if AdminConsole.gui then return AdminConsole.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "AdminConsole"
    if gui.Enabled ~= nil then gui.Enabled = true end
    AdminConsole.gui = gui
    if AdminConsole.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then gui.Parent = pgui end
    end
    return gui
end

function AdminConsole:start(manager, admins)
    self.gameManager = manager or self.gameManager
    if admins then self.adminIds = admins end
    local gui = ensureGui()
    local window = GuiUtil.createWindow("ConsoleWindow")
    if UDim2 and type(UDim2.new)=="function" then
        window.Size = UDim2.new(0, 300, 0, 150)
        window.Position = UDim2.new(0, 0, 1, -150)
    end
    window.Name = "Window"
    window.Visible = self.visible
    gui.Window = window
    if typeof and typeof(window)=="Instance" then
        window.Parent = gui
    else
        window.Parent = gui
    end

    self.commandBox = createInstance("TextBox")
    self.commandBox.PlaceholderText = "Enter command"
    if UDim2 and type(UDim2.new)=="function" then
        self.commandBox.Position = UDim2.new(0,5,0,5)
        self.commandBox.Size = UDim2.new(1,-10,0,25)
    end
    self.outputLabel = createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.outputLabel.Position = UDim2.new(0,5,0,35)
        self.outputLabel.Size = UDim2.new(1,-10,1,-40)
    end
    self.outputLabel.Text = ""

    self.executeBtn = createInstance("TextButton")
    self.executeBtn.Text = "Run"
    if UDim2 and type(UDim2.new)=="function" then
        self.executeBtn.Position = UDim2.new(0,5,1,-30)
        self.executeBtn.Size = UDim2.new(1,-10,0,25)
    end

    GuiUtil.connectButton(self.executeBtn, function()
        AdminConsole:runCommand(self.commandBox.Text)
    end)

    window.children = window.children or {}
    table.insert(window.children, self.commandBox)
    table.insert(window.children, self.outputLabel)
    table.insert(window.children, self.executeBtn)

    return gui
end

function AdminConsole:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = gui.Window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function AdminConsole:toggle()
    if not self.gui then
        self:start(self.gameManager, self.adminIds)
    end
    self:setVisible(not self.visible)
end

function AdminConsole:isAdmin(userId)
    if not userId then return false end
    for _, id in ipairs(self.adminIds) do
        if id == userId then return true end
    end
    return false
end

function AdminConsole:runCommand(text)
    if not text or text == "" then return end

    -- Split the command string into words
    local args = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(args, word)
    end
    local cmd = table.remove(args, 1)
    local result = "Executed: " .. text

    -- Command handlers for basic game functionality
    local handlers = {
        currency = function(self, a)
            local kind = a[1]
            local amount = tonumber(a[2]) or 0
            local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
            if kind then
                CurrencySystem:add(kind, amount)
                return string.format("Added %d %s", amount, kind)
            end
        end,
        ticket = function(self, a)
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
            if kind then
                GachaSystem:addTickets(kind, amount)
                return string.format("Added %d %s tickets", amount, kind)
            end
        end,
        crystals = function(self, a)
            local amount = tonumber(a[1]) or 1
            local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
            GachaSystem:addCrystals(amount)
            return string.format("Added %d crystals", amount)
        end,
        roll = function(self, a)
            if not self.gameManager then return "No manager" end
            local kind = a[1]
            if kind == "skill" then
                local r = self.gameManager:rollSkill()
                return r and ("Rolled " .. r.name) or "No currency"
            elseif kind == "companion" then
                local r = self.gameManager:rollCompanion()
                return r and ("Rolled " .. r.name) or "No currency"
            elseif kind == "equipment" then
                local slot = a[2] or "Weapon"
                local r = self.gameManager:rollEquipment(slot)
                return r and string.format("Rolled %s (%s)", r.name, slot) or "No currency"
            end
        end,
        upgrade = function(self, a)
            if not self.gameManager then return "No manager" end
            local slot = a[1]
            local amount = tonumber(a[2]) or 1
            local currency = a[3] or "gold"
            local itemSys = self.gameManager.itemSystem
            if itemSys and slot then
                local ok = itemSys:upgradeItem(slot, amount, currency)
                if ok then
                    return string.format("Upgraded %s by %d", slot, amount)
                end
            end
            return "Upgrade failed"
        end,
    }

    local handler = handlers[cmd]
    if handler then
        local ok, msg = pcall(handler, self, args)
        if ok and msg then
            result = "Executed: " .. text .. " - " .. msg
        end
    end

    if type(self.outputLabel) == "table" then
        self.outputLabel.Text = result
    else
        local ok = pcall(function()
            self.outputLabel.Text = result
        end)
        if not ok and type(self.outputLabel) == "table" then
            self.outputLabel.Text = result
        end
    end
    return result
end

return AdminConsole

