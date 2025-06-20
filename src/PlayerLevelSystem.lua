-- PlayerLevelSystem.lua
-- Manages player experience, levels and content unlocks.

local PlayerLevelSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
local RunService = game:GetService("RunService")

---Current player level starting at ``1``.
PlayerLevelSystem.level = 1

---Current accumulated experience.
PlayerLevelSystem.exp = 0

---Experience required to reach the next level.
PlayerLevelSystem.nextExp = 100

---List of content identifiers unlocked so far.
PlayerLevelSystem.unlocked = {}

---Sets up networking on the client so server updates replicate level data.
function PlayerLevelSystem:start()
    if RunService:IsClient() then
        NetworkSystem:onClientEvent("PlayerLevelUpdate", function(lvl, xp, nextXp)
            if type(lvl) == "number" then self.level = lvl end
            if type(xp) == "number" then self.exp = xp end
            if type(nextXp) == "number" then self.nextExp = nextXp end
        end)
    end
end

-- Milestone table mapping levels to content keys that unlock at that level.
local milestones = {
    [5] = {
        unlock = "skills",
        reward = {crystals = 3, tickets = {skill = 1}},
    },
    [10] = {
        unlock = "companions",
        reward = {crystals = 5},
    },
    [20] = {
        unlock = "new_area",
        reward = {keys = {location = 1}},
    },
}

---Grants milestone rewards such as currency, tickets or keys.
-- @param reward table reward descriptor
local function grantMilestoneReward(reward)
    if not reward then return end
    local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
    local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
    local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
    if reward.crystals then
        CurrencySystem:add("crystal", reward.crystals)
    end
    if reward.tickets then
        for kind, amt in pairs(reward.tickets) do
            GachaSystem.tickets[kind] = (GachaSystem.tickets[kind] or 0) + amt
        end
    end
    if reward.keys then
        for kind, amt in pairs(reward.keys) do
            KeySystem:addKey(kind, amt)
        end
    end
end

---Returns ``true`` when the specified content identifier has been unlocked.
-- @param key string content identifier
-- @return boolean
function PlayerLevelSystem:isUnlocked(key)
    for _, k in ipairs(self.unlocked) do
        if k == key then
            return true
        end
    end
    return false
end

---Unlocks content and applies milestone rewards when a level is reached.
-- @param lvl number level that was reached
function PlayerLevelSystem:unlockForLevel(lvl)
    local entry = milestones[lvl]
    if not entry then return end
    if type(entry) == "string" then
        table.insert(self.unlocked, entry)
    elseif type(entry) == "table" then
        if entry.unlock then
            table.insert(self.unlocked, entry.unlock)
        end
        grantMilestoneReward(entry.reward)
    end
end

---Checks if enough experience was gained to advance the player's level.
function PlayerLevelSystem:checkThreshold()
    while self.exp >= self.nextExp do
        self.exp = self.exp - self.nextExp
        self.level = self.level + 1
        -- Increase required experience slightly each level
        self.nextExp = math.floor(self.nextExp * 1.2)
        self:unlockForLevel(self.level)
        -- notify listeners of the level up
        local ev = EventManager:Get("PlayerLevelUp")
        ev:Fire(self.level)
        if RunService:IsServer() then
            NetworkSystem:fireAllClients("PlayerLevelUpdate", self.level, self.exp, self.nextExp)
        end
    end
end

---Adds experience to the player and processes level ups.
-- @param amount number non-negative experience amount to add
function PlayerLevelSystem:addExperience(amount)
    assert(type(amount) == "number" and amount >= 0, "amount must be non-negative")
    self.exp = self.exp + amount
    self:checkThreshold()
    if RunService:IsServer() then
        NetworkSystem:fireAllClients("PlayerLevelUpdate", self.level, self.exp, self.nextExp)
    end
end

---Serializes the current player level data for persistence.
-- @return table plain table with level, exp and unlocks
function PlayerLevelSystem:saveData()
    return {
        level = self.level,
        exp = self.exp,
        nextExp = self.nextExp,
        unlocked = self.unlocked,
    }
end

---Loads level data previously produced by ``saveData``.
-- Unknown fields are ignored.
-- @param data table data table
function PlayerLevelSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.level) == "number" then
        self.level = data.level
    end
    if type(data.exp) == "number" then
        self.exp = data.exp
    end
    if type(data.nextExp) == "number" then
        self.nextExp = data.nextExp
    end
    if type(data.unlocked) == "table" then
        self.unlocked = {}
        for i, v in ipairs(data.unlocked) do
            self.unlocked[i] = v
        end
    end
    if RunService:IsServer() then
        NetworkSystem:fireAllClients("PlayerLevelUpdate", self.level, self.exp, self.nextExp)
    end
end

return PlayerLevelSystem
