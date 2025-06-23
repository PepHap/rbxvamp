local GuiUtil = {}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local okTween, TweenService = pcall(function()
    return game:GetService("TweenService")
end)
if not okTween then TweenService = nil end

-- Utility to ensure we always pass a Color3 to Roblox APIs.
-- When running in a test environment the theme tables may contain
-- simple RGB fields instead of a Color3. Convert those tables when
-- possible so TweenService:Create never receives a plain Lua table.
local function toColor3(value)
    if typeof and typeof(value) == "Color3" then
        return value
    end
    if type(value) == "table" and value.r and value.g and value.b and Color3 then
        if Color3.fromRGB then
            return Color3.fromRGB(value.r, value.g, value.b)
        elseif Color3.new then
            return Color3.new(value.r/255, value.g/255, value.b/255)
        end
    end
    return value
end

-- internal helper for creating a Roblox Instance when available
local function createInstance(className)
    if typeof and Instance and type(Instance.new) == "function" then
        return Instance.new(className)
    end
    return {ClassName = className}
end

local function parent(child, parentObj)
    if not child or not parentObj then return end
    -- remove from previous parent table if necessary
    if type(child) == "table" and child.Parent and child.Parent ~= parentObj then
        local prev = child.Parent
        if type(prev) == "table" and prev.children then
            for i, c in ipairs(prev.children) do
                if c == child then
                    table.remove(prev.children, i)
                    break
                end
            end
        end
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
        for _, c in ipairs(parentObj.children) do
            if c == child then
                return
            end
        end
        table.insert(parentObj.children, child)
    end
end

GuiUtil.parent = parent

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
    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then
        return core
    end
    return nil
end

---Adds UIAspectRatioConstraint and UISizeConstraint for adaptive sizing.
---@param frame table|Instance Frame to modify
---@param ratio number? desired aspect ratio
---@param minX number? minimum width in pixels
---@param minY number? minimum height in pixels
---@param maxX number? maximum width in pixels
---@param maxY number? maximum height in pixels
function GuiUtil.applyResponsive(frame, ratio, minX, minY, maxX, maxY)
    if not frame then return end
    ratio = ratio or 1.5
    local aspect = createInstance("UIAspectRatioConstraint")
    aspect.Name = "Aspect"
    if aspect.AspectRatio ~= nil then
        aspect.AspectRatio = ratio
    end
    parent(aspect, frame)

    local sizeConst = createInstance("UISizeConstraint")
    sizeConst.Name = "SizeLimit"
    if sizeConst.MinSize and Vector2 and Vector2.new then
        sizeConst.MinSize = Vector2.new(minX or 150, minY or 100)
        sizeConst.MaxSize = Vector2.new(maxX or 600, maxY or 400)
    elseif type(sizeConst) == "table" then
        sizeConst.MinSize = {x = minX or 150, y = minY or 100}
        sizeConst.MaxSize = {x = maxX or 600, y = maxY or 400}
    end
    parent(sizeConst, frame)
end

---Adds a simple cross decoration using thin Frames around the edges.
---@param frame table|Instance Frame to decorate
function GuiUtil.addCrossDecor(frame)
    if not frame then return end
    local positions = {
        Top = {UDim2.new(0,0,0,0), UDim2.new(1,0,0,2)},
        Bottom = {UDim2.new(0,0,1,-2), UDim2.new(1,0,0,2)},
        Left = {UDim2.new(0,0,0,0), UDim2.new(0,2,1,0)},
        Right = {UDim2.new(1,-2,0,0), UDim2.new(0,2,1,0)},
    }
    for name, vals in pairs(positions) do
        local bar = createInstance("Frame")
        bar.Name = name
        bar.BorderSizePixel = 0
        if Theme and Theme.colors then
            bar.BackgroundColor3 = toColor3(Theme.colors.buttonBackground)
        end
        if UDim2 and type(UDim2.new)=="function" then
            bar.Position = vals[1]
            bar.Size = vals[2]
        end
        parent(bar, frame)
    end
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
        -- Provide a visible background when no theme is available
        frame.BackgroundTransparency = Theme and 1 or 0.2
    end
    if frame.BackgroundColor3 ~= nil and not Theme then
        local col = Color3 and Color3.fromRGB and Color3.fromRGB(20, 20, 30)
            or {r = 20, g = 20, b = 30}
        frame.BackgroundColor3 = toColor3(col)
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
    GuiUtil.applyResponsive(frame)
    GuiUtil.addCrossDecor(frame)
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
    local hoverColor = Theme and Theme.colors and toColor3(Theme.colors.buttonHover)
    local normalColor = toColor3(button.BackgroundColor3)
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

---Highlights or unhighlights a button using theme colors.
--  When a highlight color is defined in ``UITheme``, this will tween the
--  background to that color when ``on`` is true and restore the original
--  color when false.
---@param button table|Instance TextButton to modify
---@param on boolean whether to highlight
function GuiUtil.highlightButton(button, on)
    if not button then return end
    local highlight = Theme and Theme.colors and toColor3(Theme.colors.highlight)
    if not highlight then return end
    local normal = toColor3(button.BackgroundColor3)
    if button._origColor == nil then
        button._origColor = normal
    end
    local target = on and highlight or button._origColor
    if TweenService and typeof and typeof(button) == "Instance" then
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = target})
        tween:Play()
    else
        button.BackgroundColor3 = target
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
        if button.TouchTap then
            button.TouchTap:Connect(callback)
        end
    else
        button.onClick = callback
    end
    GuiUtil.applyHoverEffect(button)
end

return GuiUtil
