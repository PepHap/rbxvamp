-- ScoreboardSystem.lua
-- Tracks the highest stage reached by each player and shares the top scores.

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local ScoreboardSystem = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    datastore = nil,
    storeName = "Scoreboard",
    scores = {},
    levelSystem = nil,
    networkSystem = nil,
}

---Initializes the datastore and loads existing scores.
function ScoreboardSystem:start(levelSys, netSys)
    self.levelSystem = levelSys or self.levelSystem or require(script.Parent:WaitForChild("LevelSystem"))
    self.networkSystem = netSys or self.networkSystem or require(script.Parent:WaitForChild("NetworkSystem"))
    if self.useRobloxObjects and game and game.GetService then
        local ok, dsService = pcall(function()
            return game:GetService("DataStoreService")
        end)
        if ok and dsService then
            local success, store = pcall(function()
                return dsService:GetDataStore(self.storeName)
            end)
            if success then
                self.datastore = store
                local ok2, data = pcall(function()
                    return store:GetAsync("scores")
                end)
                if ok2 and type(data) == "table" then
                    self.scores = data
                end
            end
        end
    end
    EventManager:Get("LevelAdvance"):Connect(function()
        ScoreboardSystem:recordProgress()
    end)
    self:broadcast()
end

---Saves the scoreboard table back to the datastore.
function ScoreboardSystem:save()
    if not self.datastore then return end
    pcall(function()
        self.datastore:SetAsync("scores", self.scores)
    end)
end

---Returns a sorted list of the top scores.
-- @param count number how many entries to return
function ScoreboardSystem:getTop(count)
    local list = {}
    for id, info in pairs(self.scores) do
        table.insert(list, {id = id, name = info.name, stage = info.stage})
    end
    table.sort(list, function(a, b)
        return a.stage > b.stage
    end)
    count = count or #list
    while #list > count do
        table.remove(list)
    end
    return list
end

---Broadcasts the current scoreboard to all clients.
function ScoreboardSystem:broadcast()
    if self.networkSystem and self.networkSystem.fireAllClients then
        local top = self:getTop(10)
        self.networkSystem:fireAllClients("ScoreboardUpdate", top)
    end
end

---Records the player's new highest stage when it increases.
function ScoreboardSystem:recordProgress()
    if not self.useRobloxObjects then return end
    local players = game:GetService("Players")
    if not players then return end
    local player = players:GetPlayers()[1]
    if not player then return end
    local stage = self.levelSystem.highestClearedStage or 0
    local key = tostring(player.UserId)
    local entry = self.scores[key]
    if not entry or stage > entry.stage then
        self.scores[key] = {name = player.Name, stage = stage}
        self:save()
        self:broadcast()
    end
end

return ScoreboardSystem
