local GachaUI = {}
local UIBridge = require(script.Parent:WaitForChild("UIBridge"))
local Network = require(script.Parent:WaitForChild("NetworkClient"))
local MessageUI = require(script.Parent:WaitForChild("MessageUI"))

GachaUI.frame = nil
GachaUI.open1 = nil
GachaUI.open10 = nil
GachaUI.open1Buttons = {}
GachaUI.open10Buttons = {}
GachaUI.banner1 = nil
GachaUI.allBanners = {}
GachaUI.resultConn = nil
GachaUI.currentKind = "skill"
GachaUI.expectedCount = nil
GachaUI.resultBuffer = {}

-- Wait until the GUI has been loaded through ``UIBridge``.
local function findButtons(root)
    if not root then
        return
    end

    local open1Candidates = {}
    local open10Candidates = {}
    for _, obj in ipairs(root:GetDescendants()) do
        local txt = string.lower(obj.Name)
        if obj:IsA("TextButton") or obj:IsA("TextLabel") then
            txt = txt .. " " .. string.lower(obj.Text or "")
        end
        local lbl = obj:FindFirstChildWhichIsA("TextLabel")
        if lbl then
            txt = txt .. " " .. string.lower(lbl.Text or "")
        end

        if txt:find("open%s*1") or txt:find("x1") or txt:find("open1") or txt:find("openbutton1") then
            table.insert(open1Candidates, obj)
        elseif txt:find("open%s*10") or txt:find("x10") or txt:find("open10") or txt:find("openbutton10") then
            table.insert(open10Candidates, obj)
        elseif txt:find("openbutton") then
            table.insert(open1Candidates, obj)
        elseif obj:IsA("Frame") and txt:find("gachabanner") then
            table.insert(GachaUI.allBanners, obj)
            if obj.Name == "GachaBanner1" then
                GachaUI.banner1 = obj
            end
        end
    end

    GachaUI.open1Buttons = open1Candidates
    GachaUI.open10Buttons = open10Candidates
    GachaUI.open1 = GachaUI.open1 or open1Candidates[1]
    GachaUI.open10 = GachaUI.open10 or open10Candidates[1] or open1Candidates[2]
end

local function connectButtons()
    local function hook(obj, action)
        if not obj or obj:GetAttribute("_connected") then return end
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            -- https://create.roblox.com/docs/reference/engine/events/TextButton/MouseButton1Click
            obj.MouseButton1Click:Connect(action)
        elseif obj:IsA("GuiObject") then
            obj.Active = true
            obj.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    action()
                end
            end)
        else
            return
        end
        obj:SetAttribute("_connected", true)
    end

    local function hookAll(btn, action)
        hook(btn, action)
        for _, child in ipairs(btn:GetDescendants()) do
            hook(child, action)
        end
    end

    for _, btn in ipairs(GachaUI.open1Buttons) do
        hookAll(btn, function()
            GachaUI:roll(1)
        end)
    end

    for _, btn in ipairs(GachaUI.open10Buttons) do
        hookAll(btn, function()
            GachaUI:roll(10)
        end)
    end
end

local function connectResult()
    if GachaUI.resultConn then
        GachaUI.resultConn:Disconnect()
        GachaUI.resultConn = nil
    end
    if not Network.onClientEvent then
        return
    end
    GachaUI.resultConn = Network:onClientEvent("GachaResult", function(kind, reward)
        if reward then
            table.insert(GachaUI.resultBuffer, reward.name or "?")
            if GachaUI.expectedCount and #GachaUI.resultBuffer >= GachaUI.expectedCount then
                local text = table.concat(GachaUI.resultBuffer, ", ")
                MessageUI.show("Вы получили: " .. text)
                GachaUI.resultBuffer = {}
                GachaUI.expectedCount = nil
            end
        else
            MessageUI.show("Не удалось открыть")
            GachaUI.resultBuffer = {}
            GachaUI.expectedCount = nil
        end
    end)
end

local function hideAllBanners()
    for _, frame in ipairs(GachaUI.allBanners) do
        frame.Visible = false
    end
end

local function showBanner1()
    if not GachaUI.banner1 then
        return
    end
    hideAllBanners()
    GachaUI.banner1.Visible = true
    GachaUI.currentKind = "skill"
end

function GachaUI:roll(count)
    count = count or 1
    if Network and Network.fireServer then
        connectResult()
        GachaUI.expectedCount = count
        GachaUI.resultBuffer = {}
        Network:fireServer("GachaRequest", GachaUI.currentKind, count)
    end
end

-- Hides the gacha window if it is visible.
-- https://create.roblox.com/docs/reference/engine/classes/GuiObject#Visible
function GachaUI.hide()
    if GachaUI.frame then
        hideAllBanners()
        GachaUI.frame.Visible = false
    end
end

function GachaUI.show()
    UIBridge.waitForGui()
    local frame = GachaUI.frame or UIBridge.waitForFrame("GachaFrame") or UIBridge.waitForFrame("SummonFrame")
    if not frame then return end
    GachaUI.frame = frame
    findButtons(frame)
    connectButtons()
    connectResult()
    hideAllBanners()
    showBanner1()
    frame.Visible = true
end

function GachaUI.toggle()
    -- Wait for the ScreenGui before searching for the gacha frame
    UIBridge.waitForGui()
    local frame = GachaUI.frame or UIBridge.waitForFrame("GachaFrame") or UIBridge.waitForFrame("SummonFrame")
    if not frame then return end
    GachaUI.frame = frame
    findButtons(frame)
    connectButtons()
    connectResult()
    hideAllBanners()
    showBanner1()
    frame.Visible = not frame.Visible
end

function GachaUI.init()
    UIBridge.waitForGui()
    GachaUI.frame = UIBridge.waitForFrame("GachaFrame") or UIBridge.waitForFrame("SummonFrame")
    if GachaUI.frame then
        GachaUI.frame.Visible = false
        findButtons(GachaUI.frame)
        connectButtons()
        connectResult()
        hideAllBanners()
        showBanner1()
    end
end

return GachaUI
