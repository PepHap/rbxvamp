local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local MenuUI = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    window = nil,
    contentFrame = nil,
    tabs = {},
    tabButtons = {},
    currentTab = 1,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local InventoryUISystem = require(script.Parent:WaitForChild("InventoryUISystem"))
local SkillUISystem = require(script.Parent:WaitForChild("SkillUISystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if MenuUI.useRobloxObjects and typeof and Instance and type(Instance.new)=="function" then
        local inst = Instance.new(className)
        if Theme then
            if className == "TextLabel" then Theme.styleLabel(inst)
            elseif className == "TextButton" then Theme.styleButton(inst)
            elseif className == "Frame" then Theme.styleWindow(inst) end
        end
        return inst
    end
    local tbl = {ClassName = className}
    if Theme then
        if className == "TextLabel" then Theme.styleLabel(tbl)
        elseif className == "TextButton" then Theme.styleButton(tbl)
        elseif className == "Frame" then Theme.styleWindow(tbl) end
    end
    return tbl
end

local function parent(child, parentObj)
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.parent(child, parentObj)
end

local function ensureGui()
    if MenuUI.gui then return MenuUI.gui end
    local gui = createInstance("ScreenGui")
    gui.Name = "MenuUI"
    MenuUI.gui = gui
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if MenuUI.useRobloxObjects then
        local pgui = GuiUtil.getPlayerGui()
        if pgui then gui.Parent = pgui end
    end
    return gui
end

function MenuUI:addDefaultTabs()
    if #self.tabs > 0 then return end
    self:addTab("Inventory", InventoryUISystem)
    self:addTab("Skills", SkillUISystem)
end

function MenuUI:addTab(name, system)
    table.insert(self.tabs, {name=name, system=system})
end

function MenuUI:start()
    if self.window then
        local gui = ensureGui()
        if self.window.Parent ~= gui then
            parent(self.window, gui)
            self.gui = gui
        end
        return
    end
    self:addDefaultTabs()
    local gui = ensureGui()
    self.window = GuiUtil.createWindow("MenuWindow")
    if UDim2 and type(UDim2.new)=="function" then
        self.window.Size = UDim2.new(1, 0, 1, 0)
        self.window.Position = UDim2.new(0, 0, 0, 0)
    end
    parent(self.window, gui)

    self.contentFrame = createInstance("Frame")
    if UDim2 and type(UDim2.new)=="function" then
        self.contentFrame.Position = UDim2.new(0, 0, 0, 30)
        self.contentFrame.Size = UDim2.new(1, 0, 1, -30)
    end
    parent(self.contentFrame, self.window)

    for i,tab in ipairs(self.tabs) do
        local btn = createInstance("TextButton")
        btn.Text = tab.name
        if UDim2 and type(UDim2.new)=="function" then
            btn.Position = UDim2.new(0, (i-1)*100, 0, 0)
            btn.Size = UDim2.new(0, 100, 0, 30)
        end
        parent(btn, self.window)
        self.tabButtons[i] = btn
        GuiUtil.connectButton(btn, function()
            MenuUI:showTab(i)
        end)
        tab.system:start(nil, self.contentFrame)
        tab.system:setVisible(false)
    end
    self:setVisible(self.visible)
    if #self.tabs > 0 then
        self:showTab(self.currentTab)
    end
end

function MenuUI:showTab(index)
    self.currentTab = index
    for i,tab in ipairs(self.tabs) do
        if tab.system and tab.system.setVisible then
            tab.system:setVisible(i==index)
        end
    end
end

---Finds a tab index by its name.
-- @param name string tab name
-- @return number? index or nil
function MenuUI:getTabIndex(name)
    for i, tab in ipairs(self.tabs) do
        if tab.name == name then
            return i
        end
    end
    return nil
end

---Shows the specified tab by name and ensures the menu is visible.
-- @param name string tab name
function MenuUI:openTab(name)
    if not self.gui then
        self:start()
    end
    local idx = self:getTabIndex(name)
    if idx then
        self:showTab(idx)
    end
    self:setVisible(true)
end

function MenuUI:setVisible(on)
    self.visible = not not on
    local gui = ensureGui()
    local parentGui = self.window or gui
    GuiUtil.setVisible(parentGui, self.visible)
end

function MenuUI:toggle()
    if not self.gui then
        self:start()
    end
    self:setVisible(not self.visible)
end

return MenuUI
