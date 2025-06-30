local MessageUI = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))

MessageUI.label = nil
local DEFAULT_TIME = 3

function MessageUI.init()
    UIBridge.waitForGui()
    local gui = UIBridge.getScreenGui()
    if gui and not MessageUI.label then
        local lbl = Instance.new("TextLabel")
        lbl.Name = "MessageLabel"
        lbl.BackgroundColor3 = Color3.new(0,0,0)
        lbl.BackgroundTransparency = 0.5
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.AnchorPoint = Vector2.new(0.5,0)
        lbl.Position = UDim2.new(0.5,0,0.05,0)
        lbl.Size = UDim2.new(0,400,0,40)
        lbl.Visible = false
        lbl.TextScaled = true
        lbl.Parent = gui
        MessageUI.label = lbl
    end
end

function MessageUI.show(text, duration)
    if not MessageUI.label then
        MessageUI.init()
    end
    local lbl = MessageUI.label
    if not lbl then return end
    lbl.Text = tostring(text)
    lbl.Visible = true
    duration = duration or DEFAULT_TIME
    task.spawn(function()
        task.wait(duration)
        if lbl and lbl.Visible then
            lbl.Visible = false
        end
    end)
end

return MessageUI
