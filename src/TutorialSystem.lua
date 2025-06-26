-- TutorialSystem.lua
-- Shows simple hints to guide new players.

local TutorialSystem = {
    shown = {}
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))

local function display(text)
    local gui = GuiUtil.getPlayerGui and GuiUtil.getPlayerGui()
    if not gui then return end
    local lbl
    if typeof and Instance and type(Instance.new)=="function" then
        lbl = Instance.new("TextLabel")
    else
        lbl = {ClassName = "TextLabel"}
    end
    lbl.Name = "HintLabel"
    lbl.Text = text
    if lbl.Parent ~= nil then
        lbl.Parent = nil
    end
    if GuiUtil.styleLabel then
        GuiUtil.styleLabel(lbl)
    end
    if lbl.Destroy then
        lbl.Parent = gui
        if task and task.delay then
            task.delay(5, function()
                if lbl and lbl.Destroy then
                    lbl:Destroy()
                end
            end)
        end
    else
        lbl.Parent = gui
        lbl.lifetime = 5
        gui.children = gui.children or {}
        table.insert(gui.children, lbl)
    end
end

function TutorialSystem:start()
    EventManager:Get("LevelStart"):Connect(function(level)
        if level == 1 and not TutorialSystem.shown["move"] then
            TutorialSystem.shown["move"] = true
            display("Use WASD to move and click to attack")
        end
    end)
    EventManager:Get("SpawnBoss"):Connect(function()
        if not TutorialSystem.shown["boss"] then
            TutorialSystem.shown["boss"] = true
            display("Defeat the boss to progress!")
        end
    end)
end

return TutorialSystem
