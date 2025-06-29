local GuiXmlLoader = require(script.Parent:WaitForChild("GuiXmlLoader"))

local UIBridge = {}

local rootGui
local cache = {}

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
        cache[name] = GuiXmlLoader.findFirstDescendant(rootGui, name)
    end
    return cache[name]
end

return UIBridge
