-- PartyUISystem.lua
-- Minimal interface for managing parties and raids

local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local PartyUI = {
    useRobloxObjects = detectRoblox(),
    gui = nil,
    window = nil,
    listLabel = nil,
    readyStates = {},
    partyMembers = nil,
    isReady = false,
    visible = false,
}

local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local ok, Theme = pcall(function()
    return require(script.Parent:WaitForChild("UITheme"))
end)
if not ok then Theme = nil end

local function createInstance(className)
    if PartyUI.useRobloxObjects and typeof and Instance then
        local inst = Instance.new(className)
        if className == "ScreenGui" and inst.IgnoreGuiInset ~= nil then inst.IgnoreGuiInset = true end
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

local function parent(child, p)
    GuiUtil.parent(child, p)
end

local function ensureGui()
    if PartyUI.gui and (not PartyUI.useRobloxObjects or PartyUI.gui.Parent) then
        return PartyUI.gui
    end
    local pgui
    if PartyUI.useRobloxObjects then
        pgui = GuiUtil.getPlayerGui()
        if pgui then
            local existing = pgui:FindFirstChild("PartyUI")
            if existing then
                PartyUI.gui = existing
                return existing
            end
        end
    end
    local gui = createInstance("ScreenGui")
    gui.Name = "PartyUI"
    local GuiUtil = require(script.Parent:WaitForChild("GuiUtil"))
    GuiUtil.makeFullScreen(gui)
    if gui.Enabled ~= nil then
        gui.Enabled = true
    end
    if gui.ResetOnSpawn ~= nil then
        gui.ResetOnSpawn = false
    end
    PartyUI.gui = gui
    if PartyUI.useRobloxObjects and pgui then
        gui.Parent = pgui
    end
    return gui
end

function PartyUI:start()
    local gui = ensureGui()
    if PartyUI.window then
        if PartyUI.window.Parent ~= gui then
            parent(PartyUI.window, gui)
        end
        return
    end
    local window = createInstance("Frame")
    window.Name = "PartyWindow"
    PartyUI.window = window
    local createBtn = createInstance("TextButton")
    createBtn.Text = "Create Party"
    local leaveBtn = createInstance("TextButton")
    leaveBtn.Text = "Leave Party"
    local raidBtn = createInstance("TextButton")
    raidBtn.Text = "Start Raid"
    local readyBtn = createInstance("TextButton")
    readyBtn.Text = "Ready"
    local inviteBox = createInstance("TextBox")
    inviteBox.PlaceholderText = "Player"
    local inviteBtn = createInstance("TextButton")
    inviteBtn.Text = "Invite"
    local acceptBtn = createInstance("TextButton")
    acceptBtn.Text = "Accept"
    acceptBtn.Visible = false
    local declineBtn = createInstance("TextButton")
    declineBtn.Text = "Decline"
    declineBtn.Visible = false
    local list = createInstance("TextLabel")
    list.Text = "No Party"
    PartyUI.listLabel = list
    parent(window, gui)
    parent(createBtn, window)
    parent(leaveBtn, window)
    parent(raidBtn, window)
    parent(readyBtn, window)
    parent(inviteBox, window)
    parent(inviteBtn, window)
    parent(acceptBtn, window)
    parent(declineBtn, window)
    parent(list, window)
    if UDim2 then
        window.Position = UDim2.new(0, 10, 0, 10)
        window.Size = UDim2.new(0, 200, 0, 190)
        createBtn.Position = UDim2.new(0, 10, 0, 10)
        createBtn.Size = UDim2.new(0, 180, 0, 30)
        leaveBtn.Position = UDim2.new(0, 10, 0, 50)
        leaveBtn.Size = UDim2.new(0, 180, 0, 30)
        raidBtn.Position = UDim2.new(0, 10, 0, 90)
        raidBtn.Size = UDim2.new(0, 180, 0, 30)
        readyBtn.Position = UDim2.new(0, 10, 0, 130)
        readyBtn.Size = UDim2.new(0, 180, 0, 30)
        inviteBox.Position = UDim2.new(0, 10, 0, 170)
        inviteBox.Size = UDim2.new(0, 120, 0, 30)
        inviteBtn.Position = UDim2.new(0, 140, 0, 170)
        inviteBtn.Size = UDim2.new(0, 50, 0, 30)
        acceptBtn.Position = UDim2.new(0, 10, 0, 210)
        acceptBtn.Size = UDim2.new(0, 80, 0, 30)
        declineBtn.Position = UDim2.new(0, 110, 0, 210)
        declineBtn.Size = UDim2.new(0, 80, 0, 30)
        list.Position = UDim2.new(0, 10, 0, 250)
        list.Size = UDim2.new(0, 180, 0, 16)
    end
    GuiUtil.connectButton(createBtn, function()
        NetworkSystem:fireServer("PartyRequest", "create")
    end)
    GuiUtil.connectButton(leaveBtn, function()
        NetworkSystem:fireServer("PartyRequest", "leave")
    end)
    GuiUtil.connectButton(raidBtn, function()
        NetworkSystem:fireServer("RaidRequest")
    end)
    GuiUtil.connectButton(readyBtn, function()
        PartyUI.isReady = not PartyUI.isReady
        readyBtn.Text = PartyUI.isReady and "Unready" or "Ready"
        NetworkSystem:fireServer("RaidReady", PartyUI.isReady)
    end)
    GuiUtil.connectButton(inviteBtn, function()
        if inviteBox.Text and inviteBox.Text ~= "" then
            NetworkSystem:fireServer("PartyInvite", inviteBox.Text)
            inviteBox.Text = ""
        end
    end)
    GuiUtil.connectButton(acceptBtn, function()
        NetworkSystem:fireServer("PartyResponse", "accept")
        acceptBtn.Visible = false
        declineBtn.Visible = false
    end)
    GuiUtil.connectButton(declineBtn, function()
        NetworkSystem:fireServer("PartyResponse", "decline")
        acceptBtn.Visible = false
        declineBtn.Visible = false
    end)
    local function updateList()
        if PartyUI.partyMembers and #PartyUI.partyMembers > 0 then
            local names = {}
            for _, m in ipairs(PartyUI.partyMembers) do
                local mark = PartyUI.readyStates[m] and "*" or ""
                table.insert(names, mark .. tostring(m))
            end
            list.Text = table.concat(names, ", ")
        else
            list.Text = "No Party"
        end
    end

    NetworkSystem:onClientEvent("PartyUpdated", function(id, members)
        PartyUI.partyMembers = members
        updateList()
    end)
    NetworkSystem:onClientEvent("PartyInvite", function(fromPlayer)
        list.Text = tostring(fromPlayer) .. " invited you"
        acceptBtn.Visible = true
        declineBtn.Visible = true
    end)
    NetworkSystem:onClientEvent("PartyResponse", function(target, response)
        if response == "accept" then
            list.Text = tostring(target) .. " joined"
        end
    end)
    NetworkSystem:onClientEvent("PartyJoinFailed", function(reason)
        if reason == "full" then
            list.Text = "Party is full"
        elseif reason == "member" then
            list.Text = "Already in party"
        elseif reason == "invalid" then
            list.Text = "Party not found"
        else
            list.Text = "Join failed"
        end
    end)
    NetworkSystem:onClientEvent("PartyDisband", function(id)
        PartyUI.partyMembers = nil
        PartyUI.readyStates = {}
        PartyUI.isReady = false
        readyBtn.Text = "Ready"
        list.Text = "No Party"
    end)
    NetworkSystem:onClientEvent("RaidReady", function(p, ready)
        PartyUI.readyStates[p] = ready
        updateList()
    end)
    PartyUI.window.Visible = PartyUI.visible
end

function PartyUI:toggle()
    PartyUI.visible = not PartyUI.visible
    local gui = ensureGui()
    if PartyUI.window then
        PartyUI.window.Visible = PartyUI.visible
        if PartyUI.useRobloxObjects and gui then
            gui.Enabled = PartyUI.visible
        end
    end
end

return PartyUI
