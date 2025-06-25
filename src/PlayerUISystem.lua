-- PlayerUISystem.lua
-- Displays the player's current health and position using RemoteEvents.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("PlayerUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local PlayerUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    healthLabel = nil,
    positionLabel = nil,
    visible = true,
    health = nil,
    position = nil,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))
local PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if PlayerUI.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then inst.IgnoreGuiInset = true end
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function parent(child, p)
    GuiUtil.parent(child, p)
end

local function ensureGui()
    if PlayerUI.gui and (not PlayerUI.useRobloxObjects or PlayerUI.gui.Parent) then
        return PlayerUI.gui
    end
    local pgui
    if PlayerUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("PlayerUI")
            if existing then
                PlayerUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "PlayerUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    PlayerUI.gui = gui
    if PlayerUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function PlayerUI:update()
    local gui = ensureGui()
    if not self.healthLabel then
        self.healthLabel = createInstance("TextLabel")
        self.positionLabel = createInstance("TextLabel")
        parent(self.healthLabel, gui)
        parent(self.positionLabel, gui)
    end
    local hp = self.health or PlayerSystem.health or PlayerSystem.maxHealth
    local maxHp = PlayerSystem.maxHealth or 100
    self.healthLabel.Text = string.format("HP: %d/%d", hp, maxHp)
    local pos = self.position or PlayerSystem.position or {x=0,y=0,z=0}
    self.positionLabel.Text = string.format("Pos: %d,%d,%d", pos.x or 0, pos.y or 0, pos.z or 0)
    if UDim2 and type(UDim2.new)=="function" then
        self.healthLabel.Position = UDim2.new(1, -120, 0, 10)
        self.healthLabel.Size = UDim2.new(0, 110, 0, 20)
        self.positionLabel.Position = UDim2.new(1, -120, 0, 30)
        self.positionLabel.Size = UDim2.new(0, 110, 0, 20)
    end
    GuiUtil.setVisible(gui, self.visible)
end

function PlayerUI:start()
    ensureGui()
    NetworkSystem:onClientEvent("PlayerState", function(h, pos)
        self.health = h
        self.position = pos
        self:update()
    end)
    self:update()
end

function PlayerUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    GuiUtil.setVisible(gui, self.visible)
end

function PlayerUI:toggle()
    self:setVisible(not self.visible)
end

return PlayerUI

