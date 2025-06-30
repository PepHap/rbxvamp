local UIBridge = {}

local rootGui
local cache = {}

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
        cache[name] = findFirstDescendant(rootGui, name)
    end
    return cache[name]
end

return UIBridge
