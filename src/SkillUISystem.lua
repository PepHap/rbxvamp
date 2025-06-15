-- SkillUISystem.lua
-- Displays owned skills and allows upgrading them with ether.

local SkillUISystem = {
    useRobloxObjects = false,
    gui = nil,
    skillSystem = nil,
}

local SkillSystem = require(script.Parent:WaitForChild("SkillSystem"))
local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

local function createInstance(className)
    if SkillUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if SkillUISystem.gui then
        return SkillUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "SkillUI"
    SkillUISystem.gui = gui
    if SkillUISystem.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

function SkillUISystem:start(skillSys)
    self.skillSystem = skillSys or self.skillSystem or SkillSystem.new()
    self:update()
end

local function renderSkills(container, sys)
    container.children = {}
    for i, skill in ipairs(sys.skills) do
        local frame = createInstance("Frame")
        frame.Name = skill.name .. "Frame"
        parent(frame, container)

        local label = createInstance("TextLabel")
        label.Text = string.format("%s Lv.%d", skill.name, skill.level)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Text = "Upgrade"
        btn.Index = i
        parent(btn, frame)
        if btn.MouseButton1Click then
            btn.MouseButton1Click:Connect(function()
                SkillUISystem:upgrade(btn.Index)
            end)
        else
            btn.onClick = function()
                SkillUISystem:upgrade(btn.Index)
            end
        end

        frame.Label = label
        frame.Button = btn
    end
end

function SkillUISystem:update()
    local sys = self.skillSystem
    if not sys then
        return
    end
    local gui = ensureGui()
    gui.children = gui.children or {}
    gui.SkillList = gui.SkillList or createInstance("Frame")
    parent(gui.SkillList, gui)

    renderSkills(gui.SkillList, sys)
end

function SkillUISystem:upgrade(index)
    if not self.skillSystem then
        return false
    end
    local ok = self.skillSystem:upgradeSkill(index, 1)
    if ok then
        self:update()
    end
    return ok
end

return SkillUISystem
