-- CompanionUISystem.lua
-- Displays owned companions and allows upgrading them with ether.

local CompanionUISystem = {
    useRobloxObjects = false,
    gui = nil,
    companionSystem = nil,
    listFrame = nil,
}

local CompanionSystem = require(script.Parent:WaitForChild("CompanionSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

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
    if type(container) == "table" then
        container.children = {}
    elseif container.ClearAllChildren then
        container:ClearAllChildren()
    end
    for i, comp in ipairs(sys.companions) do
        local frame = createInstance("Frame")
        frame.Name = comp.name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", comp.name, comp.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        if btn.SetAttribute then
            btn:SetAttribute("Index", i)
        elseif type(btn) == "table" then
            btn.Index = i
        end
        parent(btn, frame)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                CompanionUISystem:upgrade(i)
            end)
        else
            btn.onClick = function()
                CompanionUISystem:upgrade(i)
            end
        end

        if type(frame) == "table" then
            frame.Label = label
            frame.Button = btn
        end
    end
end

function CompanionUISystem:update()
    local sys = self.companionSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    if type(gui) == "table" then
        gui.children = gui.children or {}
    end

    local container
    if self.listFrame then
        container = self.listFrame
    elseif gui.FindFirstChild then
        container = gui:FindFirstChild("CompanionList")
    end
    if not container then
        container = createInstance("Frame")
        container.Name = "CompanionList"
    end
    parent(container, gui)
    self.listFrame = container

    renderCompanions(container, sys)
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
