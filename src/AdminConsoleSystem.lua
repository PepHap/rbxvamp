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
    localPlayer = nil,
    gameManager = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))

local commandList = {
    currency = "currency <kind> <amount>",
    ticket = "ticket <kind> [amount]",
    crystals = "crystals <amount>",
    roll = "roll <skill|companion|equipment> [slot]",
    upgrade = "upgrade <slot> [amount] [currency]",
    partycreate = "partycreate",
    partyinvite = "partyinvite <player>",
    partyleave = "partyleave",
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
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then gui.Enabled = true end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    AdminConsole.gui = gui
    if AdminConsole.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function AdminConsole:start(manager, admins)
    self.gameManager = manager or self.gameManager
    if type(admins) == "table" then
        self.adminIds = admins
    end
    if not self.adminIds then
        self.adminIds = {}
    end
    if self.useRobloxObjects and game and game.Players then
        local ok, plr = pcall(function()
            return game.Players.LocalPlayer
        end)
        if ok then
            self.localPlayer = plr
        end
    end
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
    GuiUtil.makeFullScreen(window)

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("GachaResult", function(kind, reward)
            if AdminConsole.outputLabel then
                local txt = reward and ("Rolled " .. reward.name) or "No reward"
                AdminConsole.outputLabel.Text = txt
            end
        end)
    end

    self.commandBox = createInstance("TextBox")
    self.commandBox.PlaceholderText = "Enter command"
    if Theme and Theme.styleInput then Theme.styleInput(self.commandBox) end
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
        AdminConsole:runCommand(AdminConsole.commandBox.Text)
    end)

    parent(self.commandBox, window)
    parent(self.outputLabel, window)
    parent(self.hintLabel, window)
    parent(self.executeBtn, window)
    self:showHelp()
    return gui
end

---Updates the list of admin user ids.
-- @param ids table array of user ids
function AdminConsole:setAdminIds(ids)
    if type(ids) == "table" then
        self.adminIds = ids
    end
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
    if self.useRobloxObjects and self.localPlayer then
        if not self:isAdmin(self.localPlayer.UserId) then
            return
        end
    end
    self:setVisible(not self.visible)
end

function AdminConsole:isAdmin(userId)
    if not userId then return false end
    if #self.adminIds == 0 then
        return true
    end
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
    if self.useRobloxObjects and self.localPlayer then
        if not self:isAdmin(self.localPlayer.UserId) then
            if self.outputLabel then
                self.outputLabel.Text = "Not an admin"
            end
            return "Not an admin"
        end
    end

    -- Split the command string into words
    local args = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(args, word)
    end
    local cmd = table.remove(args, 1)
    if type(cmd) == "string" then
        cmd = string.lower(cmd)
    end
    local result = "Executed: " .. text

    -- Command handlers for basic game functionality
    local handlers = {
        help = function(self)
            return self:showHelp()
        end,
        currency = function(self, a)
            local kind = a[1]
            local amount = tonumber(a[2]) or 0
            if kind then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("ExchangeRequest", "addCurrency", kind, amount)
                else
                    local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
                    CurrencySystem:add(kind, amount)
                end
                return string.format("Added %d %s", amount, kind)
            end
        end,
        ticket = function(self, a)
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            if kind then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("ExchangeRequest", "addTicket", kind, amount)
                else
                    local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
                    GachaSystem:addTickets(kind, amount)
                end
                return string.format("Added %d %s tickets", amount, kind)
            end
        end,
        crystals = function(self, a)
            local amount = tonumber(a[1]) or 1
            if NetworkSystem and NetworkSystem.fireServer then
                NetworkSystem:fireServer("ExchangeRequest", "addCrystals", nil, amount)
            else
                local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
                GachaSystem:addCrystals(amount)
            end
            return string.format("Added %d crystals", amount)
        end,
        roll = function(self, a)
            local kind = a[1]
            local slot = a[2]
            if NetworkSystem and NetworkSystem.fireServer then
                NetworkSystem:fireServer("GachaRequest", kind, slot)
            end
            return "Roll requested"
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
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            if kind then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("ExchangeRequest", "ticket", kind, amount)
                    return "Ticket purchase requested"
                elseif self.gameManager then
                    local ok = self.gameManager:buyTickets(kind, amount)
                    if ok then
                        return string.format("Bought %d %s tickets", amount, kind)
                    end
                end
            end
            return "Ticket purchase failed"
        end,
        -- Purchase upgrade currency using crystals
        buycurrency = function(self, a)
            local kind = a[1]
            local amount = tonumber(a[2]) or 1
            if kind then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("ExchangeRequest", "currency", kind, amount)
                    return "Currency purchase requested"
                elseif self.gameManager then
                    local ok = self.gameManager:buyCurrency(kind, amount)
                    if ok then
                        return string.format("Bought %d %s", amount, kind)
                    end
                end
            end
            return "Currency purchase failed"
        end,
        -- Upgrade an item by spending crystals
        upgradec = function(self, a)
            local slot = a[1]
            local amount = tonumber(a[2]) or 1
            local currency = a[3]
            if slot then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("ExchangeRequest", "upgrade", nil, amount, slot, currency)
                    return "Upgrade requested"
                elseif self.gameManager then
                    local ok = self.gameManager:upgradeItemWithCrystals(slot, amount, currency)
                    if ok then
                        return string.format("Crystal upgraded %s", slot)
                    end
                end
            end
            return "Crystal upgrade failed"
        end,
        partycreate = function(self)
            if NetworkSystem and NetworkSystem.fireServer then
                NetworkSystem:fireServer("PartyRequest", "create")
            end
            return "Party create requested"
        end,
        partyinvite = function(self, a)
            local target = a[1]
            if target and NetworkSystem and NetworkSystem.fireServer then
                NetworkSystem:fireServer("PartyInvite", target)
                return "Invite sent"
            end
            return "Invite failed"
        end,
        partyleave = function(self)
            if NetworkSystem and NetworkSystem.fireServer then
                NetworkSystem:fireServer("PartyRequest", "leave")
                return "Leave requested"
            end
            return "Leave failed"
        end,
        -- Salvage an inventory item into currency
        salvageinv = function(self, a)
            local index = tonumber(a[1])
            if index then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("SalvageRequest", "inventory", index)
                    return "Salvage requested"
                elseif self.gameManager then
                    local ok = self.gameManager:salvageInventoryItem(index)
                    if ok then
                        return string.format("Salvaged inventory %d", index)
                    end
                end
            end
            return "Salvage failed"
        end,
        -- Salvage an equipped item from a slot
        salvageslot = function(self, a)
            local slot = a[1]
            if slot then
                if NetworkSystem and NetworkSystem.fireServer then
                    NetworkSystem:fireServer("SalvageRequest", "equipped", slot)
                    return "Salvage requested"
                elseif self.gameManager then
                    local ok = self.gameManager:salvageEquippedItem(slot)
                    if ok then
                        return string.format("Salvaged %s", slot)
                    end
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

