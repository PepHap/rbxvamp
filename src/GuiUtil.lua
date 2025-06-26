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
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then
            inst.IgnoreGuiInset = true
        end
        return inst
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
    local aspect
    if frame.FindFirstChild then
        aspect = frame:FindFirstChild("Aspect")
    elseif type(frame) == "table" and frame.children then
        for _, child in ipairs(frame.children) do
            if child.Name == "Aspect" then
                aspect = child
                break
            end
        end
    end
    if ratio then
        if not aspect then
            aspect = createInstance("UIAspectRatioConstraint")
            aspect.Name = "Aspect"
            parent(aspect, frame)
        end
        if aspect.AspectRatio ~= nil then
            aspect.AspectRatio = ratio
        else
            aspect.aspectRatio = ratio
        end
    end

    local sizeConst
    if frame.FindFirstChild then
        sizeConst = frame:FindFirstChild("SizeLimit")
    elseif type(frame) == "table" and frame.children then
        for _, child in ipairs(frame.children) do
            if child.Name == "SizeLimit" then
                sizeConst = child
                break
            end
        end
    end
    if minX or minY or maxX or maxY then
        if not sizeConst then
            sizeConst = createInstance("UISizeConstraint")
            sizeConst.Name = "SizeLimit"
            parent(sizeConst, frame)
        end
        if sizeConst.MinSize and Vector2 and Vector2.new then
            sizeConst.MinSize = Vector2.new(minX or 0, minY or 0)
            sizeConst.MaxSize = Vector2.new(maxX or 0, maxY or 0)
        elseif type(sizeConst) == "table" then
            sizeConst.MinSize = {x = minX or 0, y = minY or 0}
            sizeConst.MaxSize = {x = maxX or 0, y = maxY or 0}
        end
    end
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
            -- Use the highlight color with slight transparency for a modern look
            bar.BackgroundColor3 = toColor3(Theme.colors.highlight)
            bar.BackgroundTransparency = 0.2
        end
        -- Ensure decorative bars sit behind other elements
        if bar.ZIndex ~= nil then
            bar.ZIndex = 0
        else
            bar.zIndex = 0
        end
        if UDim2 and type(UDim2.new)=="function" then
            bar.Position = vals[1]
            bar.Size = vals[2]
        end
        parent(bar, frame)
    end
end

---Ensures a frame remains fully within the viewport boundaries.
---@param frame table|Instance Frame to clamp
function GuiUtil.clampToScreen(frame)
    if not frame then return end
    if not UDim2 or type(UDim2.new) ~= "function" then
        -- table fallback
        local clamp = math.clamp or function(v, lo, hi) return math.max(lo, math.min(hi, v)) end
        local size = frame.Size or {scaleX = 1, offsetX = 0, scaleY = 1, offsetY = 0}
        local pos = frame.Position or {scaleX = 0, offsetX = 0, scaleY = 0, offsetY = 0}
        size.scaleX = clamp(size.scaleX or 1, 0, 1)
        size.scaleY = clamp(size.scaleY or 1, 0, 1)
        size.offsetX = 0
        size.offsetY = 0
        pos.scaleX = clamp(pos.scaleX or 0, 0, 1 - size.scaleX)
        pos.scaleY = clamp(pos.scaleY or 0, 0, 1 - size.scaleY)
        pos.offsetX = 0
        pos.offsetY = 0
        frame.Size = size
        frame.Position = pos
        return
    end
    local ok = pcall(function()
        local clamp = math.clamp or function(v, lo, hi) return math.max(lo, math.min(hi, v)) end
        local s = frame.Size
        local p = frame.Position
        local sx = clamp(s.X.Scale, 0, 1)
        local sy = clamp(s.Y.Scale, 0, 1)
        frame.Size = UDim2.new(sx, 0, sy, 0)

        local ax, ay = 0, 0
        if frame.AnchorPoint then
            local ap = frame.AnchorPoint
            ax = (ap.X or ap.x or 0)
            ay = (ap.Y or ap.y or 0)
        end
        local minX = sx * ax
        local maxX = 1 - sx * (1 - ax)
        local minY = sy * ay
        local maxY = 1 - sy * (1 - ay)

        local px = clamp(p.X.Scale, minX, maxX)
        local py = clamp(p.Y.Scale, minY, maxY)
        frame.Position = UDim2.new(px, 0, py, 0)
    end)
    if not ok and type(frame) == "table" then
        local clamp = math.clamp or function(v, lo, hi) return math.max(lo, math.min(hi, v)) end
        local size = frame.Size or {scaleX = 1, offsetX = 0, scaleY = 1, offsetY = 0}
        local pos = frame.Position or {scaleX = 0, offsetX = 0, scaleY = 0, offsetY = 0}
        local anchor = frame.AnchorPoint or {x = 0, y = 0}
        size.scaleX = clamp(size.scaleX or 1, 0, 1)
        size.scaleY = clamp(size.scaleY or 1, 0, 1)
        size.offsetX = 0
        size.offsetY = 0
        local ax = anchor.X or anchor.x or 0
        local ay = anchor.Y or anchor.y or 0
        local minX = size.scaleX * ax
        local maxX = 1 - size.scaleX * (1 - ax)
        local minY = size.scaleY * ay
        local maxY = 1 - size.scaleY * (1 - ay)
        pos.scaleX = clamp(pos.scaleX or 0, minX, maxX)
        pos.scaleY = clamp(pos.scaleY or 0, minY, maxY)
        pos.offsetX = 0
        pos.offsetY = 0
        frame.Size = size
        frame.Position = pos
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
        -- Default windows now stretch across the entire screen. This prevents
        -- nested UI elements from exceeding the viewport when multiple systems
        -- create their own windows.
        -- https://create.roblox.com/docs/reference/engine/classes/UDim2
        local defaultSize = UDim2.new(1, 0, 1, 0)
        local defaultPos = UDim2.new(0, 0, 0, 0)
        local ok = pcall(function()
            if not frame.Size then frame.Size = defaultSize end
            if not frame.Position then frame.Position = defaultPos end
            frame.AnchorPoint = Vector2.new(0, 0)
        end)
        if not ok and type(frame) == "table" then
            frame.Size = frame.Size or defaultSize
            frame.Position = frame.Position or defaultPos
            frame.AnchorPoint = {x = 0, y = 0}
        end
    else
        -- When UDim2 isn't available, ensure table fields exist so tests
        -- referencing size and position succeed.
        frame.Size = frame.Size or {scaleX = 1, offsetX = 0, scaleY = 1, offsetY = 0}
        frame.Position = frame.Position or {scaleX = 0, offsetX = 0, scaleY = 0, offsetY = 0}
        frame.AnchorPoint = frame.AnchorPoint or {x = 0, y = 0}
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
    if frame.ClipsDescendants ~= nil then
        -- prevent children from overflowing which can push UI off-screen
        -- https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#ClipsDescendants
        frame.ClipsDescendants = true
    elseif type(frame) == "table" then
        frame.ClipsDescendants = true
    end
    if Theme and Theme.styleWindow then
        Theme.styleWindow(frame)
    end
    -- Ensure windows never exceed the viewport
    GuiUtil.makeFullScreen(frame)
    GuiUtil.clampToScreen(frame)
    -- Allow windows to fill the screen without hard limits
    GuiUtil.applyResponsive(frame, nil)
    GuiUtil.addCrossDecor(frame)
    return frame
end

---Stretches a frame to cover the entire screen.
---@param frame table|Instance Frame to modify
function GuiUtil.makeFullScreen(frame)
    if not frame then return end
    if typeof and typeof(frame) == "Instance" and frame:IsA("ScreenGui") then
        if frame.IgnoreGuiInset ~= nil then frame.IgnoreGuiInset = true end
        if frame.ResetOnSpawn ~= nil then frame.ResetOnSpawn = false end
        if frame.ZIndexBehavior ~= nil and Enum and Enum.ZIndexBehavior then
            -- use Sibling so overlapping ScreenGuis do not clip each other
            -- https://create.roblox.com/docs/reference/engine/classes/ScreenGui#ZIndexBehavior
            frame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        end
    elseif type(frame) == "table" and frame.ClassName == "ScreenGui" then
        frame.IgnoreGuiInset = true
        frame.ResetOnSpawn = false
        frame.ZIndexBehavior = "Sibling"
    end
    if UDim2 and type(UDim2.new)=="function" then
        local size = UDim2.new(1,0,1,0)
        local pos = UDim2.new(0,0,0,0)
        local anchor = Vector2 and Vector2.new(0,0) or nil
        local ok = pcall(function()
            frame.Size = size
            frame.Position = pos
            if anchor then
                frame.AnchorPoint = anchor
            elseif frame.AnchorPoint then
                frame.AnchorPoint = Vector2.new(0,0)
            end
        end)
        if not ok and type(frame)=="table" then
            frame.Size = size
            frame.Position = pos
            frame.AnchorPoint = anchor or {x=0,y=0}
        end
    else
        frame.Size = {scaleX=1,offsetX=0,scaleY=1,offsetY=0}
        frame.Position = {scaleX=0,offsetX=0,scaleY=0,offsetY=0}
        frame.AnchorPoint = {x=0,y=0}
    end

    -- Clamp after stretching to ensure the window never exceeds the viewport
    GuiUtil.clampToScreen(frame)
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

    if typeof and typeof(button) == "Instance" then
        -- Instances can't have arbitrary fields, store the color in an Attribute
        if button:GetAttribute("_origColor") == nil then
            button:SetAttribute("_origColor", normal)
        end
        local target = on and highlight or button:GetAttribute("_origColor")
        if TweenService then
            local tween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = target})
            tween:Play()
        else
            button.BackgroundColor3 = target
        end
    else
        if button._origColor == nil then
            button._origColor = normal
        end
        local target = on and highlight or button._origColor
        if TweenService then
            local tween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = target})
            tween:Play()
        else
            button.BackgroundColor3 = target
        end
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
