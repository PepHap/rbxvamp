-- AchievementSystem.lua
-- Tracks achievement progress such as enemy kills and awards rewards when completed.

local AchievementSystem = {}

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))

-- Predefined achievements indexed by id
AchievementSystem.definitions = {
    {id = "kills_10", type = "kills", goal = 10, reward = {currency = "gold", amount = 10}},
    {id = "kills_50", type = "kills", goal = 50, reward = {currency = "gold", amount = 50}},
    {id = "kills_100", type = "kills", goal = 100, reward = {currency = "gold", amount = 100}},
}

-- Runtime progress table indexed by achievement id
AchievementSystem.progress = {}

-- Ensures a progress entry exists for the given achievement id.
local function ensureProgress(id)
    local p = AchievementSystem.progress[id]
    if not p then
        AchievementSystem.progress[id] = {
            value = 0,
            completed = false,
            rewarded = false,
        }
        p = AchievementSystem.progress[id]
    end
    return p
end

---Initializes progress entries for all defined achievements.
function AchievementSystem:start()
    for _, def in ipairs(self.definitions) do
        ensureProgress(def.id)
    end
end

---Adds progress for a specific type such as "kills".
-- @param kind string progress category
-- @param amount number value to add
function AchievementSystem:addProgress(kind, amount)
    amount = amount or 1
    for _, def in ipairs(self.definitions) do
        if def.type == kind then
            local p = ensureProgress(def.id)
            if not p.completed then
                p.value = p.value + amount
                if p.value >= def.goal then
                    p.completed = true
                end
            end
        end
    end
end

---Claims an achievement reward when complete.
-- @param id string achievement identifier
-- @return boolean true if reward granted
function AchievementSystem:claim(id)
    local def
    for _, d in ipairs(self.definitions) do
        if d.id == id then
            def = d
            break
        end
    end
    local p = ensureProgress(id)
    if not def or not p or not p.completed or p.rewarded then
        return false
    end
    if def.reward and def.reward.currency and def.reward.amount then
        CurrencySystem:add(def.reward.currency, def.reward.amount)
    end
    p.rewarded = true
    return true
end

---Serializes achievement progress for saving.
-- @return table table keyed by achievement id
function AchievementSystem:saveData()
    local data = {}
    for _, def in ipairs(self.definitions) do
        local p = ensureProgress(def.id)
        data[def.id] = {
            value = p.value,
            completed = p.completed,
            rewarded = p.rewarded,
        }
    end
    return data
end

---Restores achievement progress from a saved table.
-- @param data table table previously produced by ``saveData``
function AchievementSystem:loadData(data)
    if type(data) ~= "table" then return end
    for _, def in ipairs(self.definitions) do
        local entry = data[def.id]
        if entry then
            local p = ensureProgress(def.id)
            p.value = tonumber(entry.value) or 0
            p.completed = entry.completed or false
            p.rewarded = entry.rewarded or false
        end
    end
end

return AchievementSystem
