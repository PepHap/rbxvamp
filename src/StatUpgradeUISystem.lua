-- StatUpgradeUISystem.lua
-- Simple UI for upgrading basic stats using currency

local StatUpgradeUISystem = {
    useRobloxObjects = false,
    gui = nil,
    statSystem = nil,
}

local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

local function createInstance(className)
    if StatUpgradeUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    child.Parent = parentObj
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

local function ensureGui()
    if StatUpgradeUISystem.gui then
        return StatUpgradeUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "StatUpgradeUI"
    StatUpgradeUISystem.gui = gui
    if StatUpgradeUISystem.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

function StatUpgradeUISystem:start(statSys)
    self.statSystem = statSys or self.statSystem or StatUpgradeSystem
    self:update()
end

local function renderStats(container, sys)
    container.children = {}
    for name, stat in pairs(sys.stats) do
        local frame = createInstance("Frame")
        frame.Name = name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", name, stat.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        btn.StatName = name
        parent(btn, frame)

        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                StatUpgradeUISystem:upgrade(name)
            end)
        else
            btn.onClick = function()
                StatUpgradeUISystem:upgrade(name)
            end
        end

        frame.Label = label
        frame.Button = btn
    end
end

function StatUpgradeUISystem:update()
    local sys = self.statSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    gui.children = gui.children or {}
    gui.StatList = gui.StatList or createInstance("Frame")
    parent(gui.StatList, gui)

    renderStats(gui.StatList, sys)
end

function StatUpgradeUISystem:upgrade(name)
    if not self.statSystem then
        return false
    end
    local ok = self.statSystem:upgradeStat(name, 1, "gold")
    if ok then
        self:update()
    end
    return ok
end

return StatUpgradeUISystem

