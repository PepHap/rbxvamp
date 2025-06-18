local GuiUtil = {}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local okTween, TweenService = pcall(function()
    return game:GetService("TweenService")
end)
if not okTween then TweenService = nil end

-- internal helper for creating a Roblox Instance when available
local function createInstance(className)
    if typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then
        return
    end
    if typeof and typeof(child) == "Instance" then
        if typeof(parentObj) == "Instance" then
            child.Parent = parentObj
        end
    else
        child.Parent = parentObj
    end
    if type(parentObj) == "table" then
        parentObj.children = parentObj.children or {}
        table.insert(parentObj.children, child)
    end
end

function GuiUtil.getPlayerGui()
    if not game or type(game.GetService) ~= "function" then
        return nil
    end
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok or not players then
        return nil
    end
    if players.LocalPlayer then
        local ok, pgui = pcall(function()
            return players.LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
        if ok and pgui then
            return pgui
        end
    end
    local list = players:GetPlayers()
    if list and #list > 0 then
        local p = list[1]
        if p then
            local ok, pgui = pcall(function()
                return p:WaitForChild("PlayerGui", 5)
            end)
            if ok then
                return pgui
            end
        end
    end
    return nil
end

---Creates a basic window Frame. A background image asset id may be specified,
---though no images are bundled in the repository so it remains text-only.
---When running outside of Roblox, table objects are used instead of instances.
---@param name string Name of the frame
---@param image string? asset id for an ImageLabel background
-- @return table|Instance the created Frame
function GuiUtil.createWindow(name, image)
    local frame = createInstance("Frame")
    frame.Name = name or "Window"
    if frame.BackgroundTransparency ~= nil then
        frame.BackgroundTransparency = 1
    end
    if UDim2 and type(UDim2.new)=="function" then
        local defaultSize = UDim2.new(0, 300, 0, 200)
        local defaultPos = UDim2.new(0.5, -150, 0.5, -100)
        local ok = pcall(function()
            if not frame.Size then frame.Size = defaultSize end
            if not frame.Position then frame.Position = defaultPos end
        end)
        if not ok and type(frame) == "table" then
            frame.Size = frame.Size or defaultSize
            frame.Position = frame.Position or defaultPos
        end
    end
    if image then
        local bg = createInstance("ImageLabel")
        bg.Name = "Background"
        bg.Image = image
        if UDim2 and type(UDim2.new)=="function" then
            bg.Size = UDim2.new(1, 0, 1, 0)
        end
        parent(bg, frame)
    end
    if Theme and Theme.styleWindow then
        Theme.styleWindow(frame)
    end
    return frame
end

---Sets visibility on a GUI element using either ``Enabled`` or ``Visible``.
---@param obj table|Instance GUI element to modify
---@param on boolean whether the element should be visible
function GuiUtil.setVisible(obj, on)
    if not obj then return end
    local show = not not on
    -- try Roblox properties safely
    local ok = pcall(function()
        if obj:IsA("ScreenGui") then
            obj.Enabled = show
        else
            obj.Visible = show
        end
    end)
    if not ok and type(obj) == "table" then
        if obj.Enabled ~= nil then obj.Enabled = show end
        if obj.Visible ~= nil then obj.Visible = show end
    end
end

---Applies a simple hover effect to a button by changing its background color.
-- When running inside Roblox, a Tween will smoothly transition the color.
-- In the test environment, hoverColor is stored on the table object.
---@param button table|Instance TextButton to modify
function GuiUtil.applyHoverEffect(button)
    if not button then return end
    local hoverColor = Theme and Theme.colors and Theme.colors.buttonHover
    local normalColor = button.BackgroundColor3
    if button.MouseEnter and button.MouseLeave then
        if TweenService and hoverColor and normalColor then
            local enterTween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor})
            local leaveTween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = normalColor})
            button.MouseEnter:Connect(function() enterTween:Play() end)
            button.MouseLeave:Connect(function() leaveTween:Play() end)
        else
            button.MouseEnter:Connect(function()
                if hoverColor then button.BackgroundColor3 = hoverColor end
            end)
            button.MouseLeave:Connect(function()
                if normalColor then button.BackgroundColor3 = normalColor end
            end)
        end
    else
        -- store hover color for table-based tests
        button.hoverColor = hoverColor
    end
end

---Connects a button click handler using ``Activated`` when available or
-- ``MouseButton1Click`` as a fallback. In the test environment where real
-- events are unavailable, the callback is stored in ``onClick``.
---@param button table|Instance TextButton to connect
---@param callback function function to run on activation
function GuiUtil.connectButton(button, callback)
    if not button or not callback then
        return
    end
    if button.Activated then
        button.Activated:Connect(callback)
    elseif button.MouseButton1Click then
        button.MouseButton1Click:Connect(callback)
    else
        button.onClick = callback
    end
    GuiUtil.applyHoverEffect(button)
end

return GuiUtil
