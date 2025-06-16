local GuiUtil = {}

local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

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
    child.Parent = parentObj
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
    if players.LocalPlayer and players.LocalPlayer:FindFirstChild("PlayerGui") then
        return players.LocalPlayer.PlayerGui
    end
    local list = players:GetPlayers()
    if list and #list > 0 then
        local p = list[1]
        if p then
            return p:FindFirstChild("PlayerGui") or (p.WaitForChild and p:WaitForChild("PlayerGui", 5))
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
    if image then
        local bg = createInstance("ImageLabel")
        bg.Name = "Background"
        bg.Image = image
        if UDim2 and UDim2.new then
            bg.Size = UDim2.new(1, 0, 1, 0)
        end
        parent(bg, frame)
    end
    if Theme and Theme.styleWindow then
        Theme.styleWindow(frame)
    end
    return frame
end

return GuiUtil
