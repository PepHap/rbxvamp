-- ClientQuestSystem.lua
-- Provides a safe client wrapper around QuestSystem that forwards
-- reward claims to the server and strips server-only logic.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientQuestSystem should only be required on the client", 2)
end

local QuestSystem = require(script.Parent:WaitForChild("QuestSystem"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local ClientQuestSystem = {
    quests = QuestSystem.quests
}

---Claims a quest reward by requesting the server to process it.
-- @param id string quest identifier
function ClientQuestSystem:claimReward(id)
    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("QuestClaim", id)
    end
end

---Loads quest data received from the server.
function ClientQuestSystem:loadData(data)
    QuestSystem:loadData(data)
end

---Checks if a quest is completed.
function ClientQuestSystem:isCompleted(id)
    return QuestSystem:isCompleted(id)
end

return ClientQuestSystem

