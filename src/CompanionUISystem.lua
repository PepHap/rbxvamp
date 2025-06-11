-- CompanionUISystem.lua
-- Displays owned companions and allows upgrading them with ether.

local CompanionUISystem = {
    useRobloxObjects = false,
    gui = nil,
    companionSystem = nil,
}

local CompanionSystem = require("src.CompanionSystem")
local CurrencySystem = require("src.CurrencySystem")

local function createInstance(className)
    if CompanionUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if CompanionUISystem.gui then
        return CompanionUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "CompanionUI"
    CompanionUISystem.gui = gui
    if CompanionUISystem.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

function CompanionUISystem:start(compSys)
    self.companionSystem = compSys or self.companionSystem or {companions = {}}
    self:update()
end

local function renderCompanions(container, sys)
    container.children = {}
    for i, comp in ipairs(sys.companions) do
        local frame = createInstance("Frame")
        frame.Name = comp.name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", comp.name, comp.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        btn.Index = i
        parent(btn, frame)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                CompanionUISystem:upgrade(btn.Index)
            end)
        else
            btn.onClick = function()
                CompanionUISystem:upgrade(btn.Index)
            end
        end

        frame.Label = label
        frame.Button = btn
    end
end

function CompanionUISystem:update()
    local sys = self.companionSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    gui.children = gui.children or {}
    gui.CompanionList = gui.CompanionList or createInstance("Frame")
    parent(gui.CompanionList, gui)

    renderCompanions(gui.CompanionList, sys)
end

function CompanionUISystem:upgrade(index)
    if not self.companionSystem then
        return false
    end
    local ok = self.companionSystem:upgradeCompanion(index, 1)
    if ok then
        self:update()
    end
    return ok
end

return CompanionUISystem
