-- QuestSystem.lua
-- Manages quest definitions, completion checks and reward claiming.

local QuestSystem = {}

-- Active quest table indexed by quest id
QuestSystem.quests = {}

-- CurrencySystem is used for basic reward handling
local CurrencySystem = require("src.CurrencySystem")
local KeySystem = require("src.KeySystem")

---Adds a new quest definition.
-- @param def table quest definition with fields: id, goal, reward
function QuestSystem:addQuest(def)
    assert(def and def.id, "quest definition requires an id")
    self.quests[def.id] = {
        id = def.id,
        goal = def.goal or 0,
        progress = 0,
        reward = def.reward,
        completed = false,
        rewarded = false,
    }
end

---Adds progress toward completing a quest.
-- @param id string quest identifier
-- @param amount number amount to add
function QuestSystem:addProgress(id, amount)
    local q = self.quests[id]
    if not q or q.completed then
        return
    end
    q.progress = q.progress + (amount or 0)
    if q.progress >= q.goal then
        q.completed = true
    end
end

---Returns whether the given quest is completed.
-- @param id string quest identifier
-- @return boolean
function QuestSystem:isCompleted(id)
    local q = self.quests[id]
    return q and q.completed or false
end

---Claims the reward for a completed quest if available.
-- @param id string quest identifier
-- @return boolean true if the reward was granted
function QuestSystem:claimReward(id)
    local q = self.quests[id]
    if not q or not q.completed or q.rewarded then
        return false
    end
    if q.reward then
        if q.reward.currency and q.reward.amount then
            CurrencySystem:add(q.reward.currency, q.reward.amount)
        end
        if q.reward.keys then
            for kind, amt in pairs(q.reward.keys) do
                KeySystem:addKey(kind, amt)
            end
        end
    end
    q.rewarded = true
    return true
end

return QuestSystem
