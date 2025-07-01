local UIBridge = {}

local rootGui
local cache = {}

-- Wait until a ScreenGui has been assigned via ``init``.
-- https://create.roblox.com/docs/reference/engine/classes/ScreenGui
function UIBridge.waitForGui()
    while not rootGui do
        task.wait()
    end
end

---Blocks until the named frame is available.
-- @param name string frame to locate
-- @return Instance|nil GuiObject
function UIBridge.waitForFrame(name)
    UIBridge.waitForGui()
    local frame = UIBridge.getFrame(name)
    while not frame do
        task.wait()
        frame = UIBridge.getFrame(name)
    end
    return frame
end

local function findFirstDescendant(root, name)
    if not root or not name then
        return nil
    end
    if root.FindFirstChild then
        local child = root:FindFirstChild(name)
        if child then
            return child
        end
        for _, obj in ipairs(root:GetChildren()) do
            local found = findFirstDescendant(obj, name)
            if found then
                return found
            end
        end
    end
    return nil
end

---Initializes the bridge with the given ScreenGui containing the xml UI.
-- @param gui ScreenGui
function UIBridge.init(gui)
    rootGui = gui
    cache = {}
    -- Ensure newly created UI starts hidden so windows don't flash on spawn
    -- https://create.roblox.com/docs/reference/engine/classes/GuiObject#Visible
    if gui then
        local window = gui:FindFirstChild("Window")
        if window then
            window.Visible = false
        end
        local inv = window and window:FindFirstChild("InventoryFrame")
        if inv then
            inv.Visible = false
        end
        local gacha = window and window:FindFirstChild("GachaFrame")
        if gacha then
            gacha.Visible = false
        end
    end
end

---Returns the loaded ScreenGui root.
function UIBridge.getScreenGui()
    return rootGui
end

---Returns a descendant of the UI ScreenGui by name.
--@param name string
function UIBridge.getFrame(name)
    if not rootGui then
        return nil
    end
    if cache[name] == nil then
        local searchRoot = rootGui:FindFirstChild("Window") or rootGui
        local frame = findFirstDescendant(searchRoot, name)
        -- Support alternate naming between "GachaFrame" and "SummonFrame"
        if not frame then
            if name == "GachaFrame" then
                frame = findFirstDescendant(searchRoot, "SummonFrame")
            elseif name == "SummonFrame" then
                frame = findFirstDescendant(searchRoot, "GachaFrame")
            end
        end
        cache[name] = frame
    end
    return cache[name]
end

return UIBridge
