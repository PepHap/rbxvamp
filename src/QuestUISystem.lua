local QuestUISystem = {
    useRobloxObjects = false,
    gui = nil,
    questSystem = nil,
}

local function createInstance(className)
    if QuestUISystem.useRobloxObjects and typeof and Instance and type(Instance.new) == "function" then
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
    if QuestUISystem.gui then
        return QuestUISystem.gui
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "QuestUI"
    QuestUISystem.gui = gui
    if QuestUISystem.useRobloxObjects and game and type(game.GetService) == "function" then
        local ok, players = pcall(function() return game:GetService("Players") end)
        if ok and players and players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
            gui.Parent = players.LocalPlayer.PlayerGui
        end
    end
    return gui
end

function QuestUISystem:start(questSys)
    self.questSystem = questSys or self.questSystem or require("src.QuestSystem")
    self:update()
end

function QuestUISystem:update()
    local qs = self.questSystem
    if not qs then
        return
    end
    local gui = ensureGui()
    gui.children = {}
    for id, q in pairs(qs.quests) do
        local frame = createInstance("Frame")
        frame.Name = id .. "Frame"
        parent(frame, gui)

        local label = createInstance("TextLabel")
        label.Name = "ProgressLabel"
        label.Text = string.format("%s: %d/%d", id, q.progress, q.goal)
        parent(label, frame)

        local btn = createInstance("TextButton")
        btn.Name = "ClaimButton"
        btn.Text = "Claim"
        btn.QuestId = id
        parent(btn, frame)

        if q.completed and not q.rewarded then
            if btn.MouseButton1Click then
                btn.MouseButton1Click:Connect(function()
                    QuestUISystem:claim(id)
                end)
            else
                btn.onClick = function()
                    QuestUISystem:claim(id)
                end
            end
        else
            btn.Active = false
        end

        frame.ProgressLabel = label
        frame.ClaimButton = btn
    end
end

function QuestUISystem:claim(id)
    if not self.questSystem then
        return false
    end
    local ok = self.questSystem:claimReward(id)
    if ok then
        self:update()
    end
    return ok
end

return QuestUISystem

