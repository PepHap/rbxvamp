-- LobbyUISystem.lua
-- Minimal interface for leaving the lobby.
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("LobbyUISystem should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local LobbyUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    lobbySystem = nil,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if LobbyUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then
            inst.IgnoreGuiInset = true
        end
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
    if LobbyUI.gui and (not LobbyUI.useRobloxObjects or LobbyUI.gui.Parent) then
        return LobbyUI.gui
    end
    local pgui
    if LobbyUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("LobbyUI")
            if existing then
                LobbyUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "LobbyUI"
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    LobbyUI.gui = gui
    if LobbyUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function LobbyUI:start(ls)
    self.lobbySystem = ls or self.lobbySystem or require(script.Parent:WaitForChild("ClientLobbySystem"))
    local gui = ensureGui()
    self.gui = gui
    if self.window then
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        self:setVisible(self.visible)
        return
    end
    self.window = GuiUtil.createWindow("LobbyWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.AnchorPoint = Vector2.new(0, 0)
        self.window.Position = UDim2.new(0, 0, 0, 0)
        self.window.Size = UDim2.new(1, 0, 1, 0)
        GuiUtil.clampToScreen(self.window)
    end
    parent(self.window, gui)
    local btn = createInstance("TextButton")
    btn.Text = "Exit Lobby"
    if UDim2 and type(UDim2.new)=="function" then
        btn.Position = UDim2.new(0, 10, 0, 10)
        btn.Size = UDim2.new(0, 230, 0, 30)
    end
    parent(btn, self.window)
    GuiUtil.connectButton(btn, function()
        if self.lobbySystem then
            self.lobbySystem:leave()
        end
        self:setVisible(false)
    end)
    self:setVisible(self.visible)
end

function LobbyUI:setVisible(on)
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
end

function LobbyUI:toggle()
    if not self.gui then
        self:start(self.lobbySystem)
    end
    self:setVisible(not self.visible)
end

return LobbyUI
