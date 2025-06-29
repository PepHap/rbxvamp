-- GachaUISystem.lua
-- Provides a simple interface to roll gacha rewards via buttons
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("GachaUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local GachaUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    visible = false,
    gameManager = nil,
    resultLabel = nil,
    skillButton = nil,
    companionButton = nil,
    equipmentButton = nil,
    buySkillTicketButton = nil,
    buyCompanionTicketButton = nil,
    buyEquipmentTicketButton = nil,
    buyGoldButton = nil,
    exchangeResultLabel = nil,
    window = nil,
    contentFrame = nil,
}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))

local function createInstance(className)
    if GachaUI.useRobloxObjects and typeof ~= nil and Instance and type(Instance.new) == "function" then
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
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    local gui = UIBridge.getScreenGui()
    GachaUI.gui = gui or GachaUI.gui
    return GachaUI.gui
end

local function connect(btn, callback)
    if not btn then return end
    GuiUtil.connectButton(btn, callback)
end

function GachaUI:start(manager, parentGui)
    self.gameManager = manager or self.gameManager or require(script.Parent:WaitForChild("ClientGameManager"))
    local guiRoot = ensureGui()
    local parentTarget = parentGui or guiRoot
    local xmlWindow = UIBridge.getFrame("GachaFrame")
    if not xmlWindow then
        return
    end
    self.window = xmlWindow
    self.contentFrame = xmlWindow
    if self.window.Parent ~= parentTarget then
        parent(self.window, parentTarget)
    end
    self.gui = parentTarget

    self.resultLabel = GuiXmlLoader.findFirstDescendant(xmlWindow, "ResultLabel")
    self.skillButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "SkillButton")
    self.companionButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "CompanionButton")
    self.equipmentButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "EquipmentButton")
    self.buySkillTicketButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "BuySkillTicketButton")
    self.buyCompanionTicketButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "BuyCompanionTicketButton")
    self.buyEquipmentTicketButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "BuyEquipmentTicketButton")
    self.buyGoldButton = GuiXmlLoader.findFirstDescendant(xmlWindow, "BuyGoldButton")
    self.exchangeResultLabel = GuiXmlLoader.findFirstDescendant(xmlWindow, "ExchangeResult")

    local function safeConnect(btn, callback)
        if btn then
            connect(btn, callback)
        end
    end

    safeConnect(self.skillButton, function()
        NetworkSystem:fireServer("GachaRequest", "skill")
    end)
    safeConnect(self.companionButton, function()
        NetworkSystem:fireServer("GachaRequest", "companion")
    end)
    safeConnect(self.equipmentButton, function()
        NetworkSystem:fireServer("GachaRequest", "equipment", "Weapon")
    end)
    safeConnect(self.buySkillTicketButton, function()
        GachaUI:buyTicket("skill")
    end)
    safeConnect(self.buyCompanionTicketButton, function()
        GachaUI:buyTicket("companion")
    end)
    safeConnect(self.buyEquipmentTicketButton, function()
        GachaUI:buyTicket("equipment")
    end)
    safeConnect(self.buyGoldButton, function()
        GachaUI:buyCurrency("gold")
    end)

    if NetworkSystem and NetworkSystem.onClientEvent then
        NetworkSystem:onClientEvent("GachaResult", function(kind, reward)
            if reward then
                GachaUI:showResult(reward)
            else
                GachaUI:showResult(nil)
            end
        end)
        NetworkSystem:onClientEvent("ExchangeResult", function(ok)
            if GachaUI.exchangeResultLabel then
                if ok then
                    GachaUI.exchangeResultLabel.Text = "Purchase successful"
                    if Color3 then
                        GachaUI.exchangeResultLabel.TextColor3 = Color3.new(0, 1, 0)
                    end
                else
                    GachaUI.exchangeResultLabel.Text = "Purchase failed"
                    if Color3 then
                        GachaUI.exchangeResultLabel.TextColor3 = Color3.new(1, 0, 0)
                    end
                end
                GachaUI.exchangeResultLabel.Visible = true
                if task and task.delay then
                    task.delay(2, function()
                        if GachaUI.exchangeResultLabel then
                            GachaUI.exchangeResultLabel.Visible = false
                        end
                    end)
                end
            end
        end)
    end

    self:setVisible(self.visible)
end

function GachaUI:setVisible(on)
    local newVis = not not on
    if newVis == self.visible then
        local gui = ensureGui()
        local parentGui = self.window or gui
        GuiUtil.setVisible(parentGui, self.visible)
        return
    end

    self.visible = newVis
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
    GuiUtil.clampToScreen(parentGui)
end

function GachaUI:toggle()
    if not self.gui then
        self:start(self.gameManager)
    end
    self:setVisible(not self.visible)
end

function GachaUI:showResult(result)
    self.resultLabel = self.resultLabel or createInstance("TextLabel")
    -- keep the label inside the existing container if available
    parent(self.resultLabel, self.contentFrame or self.window or ensureGui())
    if not result then
        self.resultLabel.Text = "No reward"
        return
    end
    local rarity = result.rarity or "?"
    self.resultLabel.Text = string.format("%s [%s]", result.name, rarity)
    if Theme and Theme.rarityColors and Theme.rarityColors[rarity] then
        self.resultLabel.TextColor3 = Theme.rarityColors[rarity]
    end
end

function GachaUI:rollSkill()
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "skill")
    end
end

function GachaUI:rollCompanion()
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "companion")
    end
end

function GachaUI:rollEquipment(slot)
    if NetworkSystem then
        NetworkSystem:fireServer("GachaRequest", "equipment", slot)
    end
end

function GachaUI:buyTicket(kind)
    if NetworkSystem then
        NetworkSystem:fireServer("ExchangeRequest", "ticket", kind, 1)
    end
end

function GachaUI:buyCurrency(kind)
    if NetworkSystem then
        NetworkSystem:fireServer("ExchangeRequest", "currency", kind, 1)
    end
end

return GachaUI

