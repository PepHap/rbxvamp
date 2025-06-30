local GachaUI = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local Network = require(script.Parent:WaitForChild("NetworkClient"))
local MessageUI = require(script.Parent:WaitForChild("MessageUI"))

GachaUI.frame = nil
GachaUI.open1 = nil
GachaUI.open10 = nil
GachaUI.banner1 = nil
GachaUI.allBanners = {}
GachaUI.resultConn = nil

-- Wait until the GUI has been loaded through ``UIBridge``.
local function findButtons(root)
    if not root then
        return
    end

    local list = {}
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == "OpenButton" then
            table.insert(list, obj)
        elseif obj.Name == "Open1" or obj.Name == "Open 1" then
            list[1] = list[1] or obj
        elseif obj.Name == "Open10" or obj.Name == "Open 10" then
            list[2] = list[2] or obj
        elseif obj:IsA("TextButton") then
            local text = string.lower(obj.Text or "")
            if text:find("open 1") and not list[1] then
                list[1] = obj
            elseif (text:find("open 10") or text:find("x10")) and not list[2] then
                list[2] = obj
            end
        elseif obj:IsA("ImageButton") then
            local label = obj:FindFirstChildWhichIsA("TextLabel")
            if label then
                local text = string.lower(label.Text or "")
                if text:find("open 1") and not list[1] then
                    list[1] = obj
                elseif (text:find("open 10") or text:find("x10")) and not list[2] then
                    list[2] = obj
                end
            end
        end
    end

    GachaUI.open1 = GachaUI.open1 or list[1]
    GachaUI.open10 = GachaUI.open10 or list[2] or list[3]

    if not next(GachaUI.allBanners) then
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Frame") and obj.Name:find("GachaBanner") then
                table.insert(GachaUI.allBanners, obj)
                if obj.Name == "GachaBanner1" then
                    GachaUI.banner1 = obj
                end
            end
        end
    end
end

local function connectButtons()
    local function hook(btn, action)
        if not btn or btn._connected then
            return
        end
        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
            -- https://create.roblox.com/docs/reference/engine/events/TextButton/MouseButton1Click
            btn.MouseButton1Click:Connect(action)
        else
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    action()
                end
            end)
        end
        btn._connected = true
    end

    hook(GachaUI.open1, function()
        GachaUI:roll(1)
    end)
    hook(GachaUI.open10, function()
        GachaUI:roll(10)
    end)
end

local function connectResult()
    if GachaUI.resultConn or not Network.onClientEvent then
        return
    end
    GachaUI.resultConn = Network:onClientEvent("GachaResult", function(kind, reward)
        local name = reward and reward.name or "?"
        MessageUI.show("Вы получили: " .. tostring(name))
    end)
end

local function showBanner1()
    if not GachaUI.banner1 then
        return
    end
    for _, frame in ipairs(GachaUI.allBanners) do
        frame.Visible = frame == GachaUI.banner1
    end
end

function GachaUI:roll(count)
    count = count or 1
    for i = 1, count do
        if Network and Network.fireServer then
            Network:fireServer("GachaRequest", "skill")
        end
    end
end

-- Hides the gacha window if it is visible.
-- https://create.roblox.com/docs/reference/engine/classes/GuiObject#Visible
function GachaUI.hide()
    if GachaUI.frame then
        GachaUI.frame.Visible = false
    end
end

function GachaUI.show()
    UIBridge.waitForGui()
    local frame = GachaUI.frame or UIBridge.waitForFrame("GachaFrame")
    if not frame then return end
    GachaUI.frame = frame
    if not (GachaUI.open1 and GachaUI.open10) then
        findButtons(frame)
        connectButtons()
    end
    connectResult()
    showBanner1()
    frame.Visible = true
end

function GachaUI.toggle()
    -- Wait for the ScreenGui before searching for the gacha frame
    UIBridge.waitForGui()
    local frame = GachaUI.frame or UIBridge.waitForFrame("GachaFrame")
    if not frame then return end
    GachaUI.frame = frame
    if not (GachaUI.open1 and GachaUI.open10) then
        findButtons(frame)
    end
    connectButtons()
    connectResult()
    showBanner1()
    frame.Visible = not frame.Visible
end

function GachaUI.init()
    UIBridge.waitForGui()
    GachaUI.frame = UIBridge.waitForFrame("GachaFrame")
    if GachaUI.frame then
        GachaUI.frame.Visible = false
        findButtons(GachaUI.frame)
        connectButtons()
        connectResult()
        showBanner1()
    end
end

return GachaUI
