-- LobbyUISystem.lua
-- Minimal interface for leaving the lobby.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local LobbyUI = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    gui = nil,
    window = nil,
    lobbySystem = nil,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))

local function createInstance(className)
    if LobbyUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
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
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    LobbyUI.gui = gui
    if LobbyUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function LobbyUI:start(ls)
    self.lobbySystem = ls or self.lobbySystem or require(script.Parent:WaitForChild("LobbySystem"))
    local gui = ensureGui()
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
        self.window.Size = UDim2.new(0, 250, 0, 80)
        self.window.Position = UDim2.new(0.5, -125, 0, 20)
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
    self.visible = not not on
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
