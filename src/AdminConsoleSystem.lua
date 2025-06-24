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
    hintLabel = nil,
    adminIds = {},
    gameManager = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local commandList = {
    currency = "currency <kind> <amount>",
    ticket = "ticket <kind> [amount]",
    crystals = "crystals <amount>",
    roll = "roll <skill|companion|equipment> [slot]",
    upgrade = "upgrade <slot> [amount] [currency]",
    buyticket = "buyticket <kind> [amount]",
    buycurrency = "buycurrency <kind> [amount]",
    upgradec = "upgradec <slot> [amount] [currency]",
    salvageinv = "salvageinv <index>",
    salvageslot = "salvageslot <slot>",
    help = "help",
}
AdminConsole.commandList = commandList

local function createInstance(className)
    if AdminConsole.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then inst.IgnoreGuiInset = true end
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

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if AdminConsole.gui and (not AdminConsole.useRobloxObjects or AdminConsole.gui.Parent) then
        return AdminConsole.gui
    end
    local pgui
    if AdminConsole.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("AdminConsole")
            if existing then
                AdminConsole.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "AdminConsole"
    if gui.Enabled ~= nil then gui.Enabled = true end
    AdminConsole.gui = gui
    if AdminConsole.useRobloxObjects and pgui then
        gui.Parent = pgui
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
    self.window = window
    parent(window, gui)

    self.commandBox = createInstance("TextBox")
    self.commandBox.PlaceholderText = "Enter command"
    if UDim2 and type(UDim2.new)=="function" then
        self.commandBox.Position = UDim2.new(0,5,0,5)
        self.commandBox.Size = UDim2.new(1,-10,0,25)
    end
    self.outputLabel = createInstance("TextLabel")
    if UDim2 and type(UDim2.new)=="function" then
        self.outputLabel.Position = UDim2.new(0,5,0,35)
        self.outputLabel.Size = UDim2.new(1,-10,1,-65)
    end
    self.outputLabel.Text = ""

    self.hintLabel = createInstance("TextLabel")
    self.hintLabel.Text = "Type 'help' for commands"
    if UDim2 and type(UDim2.new)=="function" then
        self.hintLabel.Position = UDim2.new(0,5,1,-55)
        self.hintLabel.Size = UDim2.new(1,-10,0,20)
    end

    self.executeBtn = createInstance("TextButton")
    self.executeBtn.Text = "Run"
    if UDim2 and type(UDim2.new)=="function" then
        self.executeBtn.Position = UDim2.new(0,5,1,-30)
        self.executeBtn.Size = UDim2.new(1,-10,0,25)
    end

    GuiUtil.connectButton(self.executeBtn, function()
        AdminConsole:runCommand(self.commandBox.Text)
    end)

    parent(self.commandBox, window)
    parent(self.outputLabel, window)
    parent(self.hintLabel, window)
    parent(self.executeBtn, window)
    self:showHelp()
    return gui
end

function AdminConsole:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
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

function AdminConsole:showHelp()
    local lines = {}
    for _, desc in pairs(self.commandList) do
        table.insert(lines, desc)
    end
    table.sort(lines)
    local text = table.concat(lines, "\n")
    if self.outputLabel then
        self.outputLabel.Text = text
    end
    return text
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
        help = function(self)
            return self:showHelp()
        end,
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
        -- Purchase gacha tickets using crystals
        buyticket = function(self, a)
            if not self.gameManager then return "No manager" end
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            if kind then
                local ok = self.gameManager:buyTickets(kind, amount)
                if ok then
                    return string.format("Bought %d %s tickets", amount, kind)
                end
            end
            return "Ticket purchase failed"
        end,
        -- Purchase upgrade currency using crystals
        buycurrency = function(self, a)
            if not self.gameManager then return "No manager" end
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            if kind then
                local ok = self.gameManager:buyCurrency(kind, amount)
                if ok then
                    return string.format("Bought %d %s", amount, kind)
                end
            end
            return "Currency purchase failed"
        end,
        -- Upgrade an item by spending crystals
        upgradec = function(self, a)
            if not self.gameManager then return "No manager" end
            local slot = a[1]
            local amount = tonumber(a[2]) or 1
            local currency = a[3]
            if slot then
                local ok = self.gameManager:upgradeItemWithCrystals(slot, amount, currency)
                if ok then
                    return string.format("Crystal upgraded %s", slot)
                end
            end
            return "Crystal upgrade failed"
        end,
        -- Salvage an inventory item into currency
        salvageinv = function(self, a)
            if not self.gameManager then return "No manager" end
            local index = tonumber(a[1])
            if index then
                local ok = self.gameManager:salvageInventoryItem(index)
                if ok then
                    return string.format("Salvaged inventory %d", index)
                end
            end
            return "Salvage failed"
        end,
        -- Salvage an equipped item from a slot
        salvageslot = function(self, a)
            if not self.gameManager then return "No manager" end
            local slot = a[1]
            if slot then
                local ok = self.gameManager:salvageEquippedItem(slot)
                if ok then
                    return string.format("Salvaged %s", slot)
                end
            end
            return "Salvage failed"
        end,
    }

    local handler = handlers[cmd]
    if handler then
        local ok, msg = pcall(handler, self, args)
        if ok and msg then
            if cmd == "help" then
                result = msg
            else
                result = "Executed: " .. text .. " - " .. msg
            end
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

