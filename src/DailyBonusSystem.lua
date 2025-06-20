-- DailyBonusSystem.lua
-- Grants a daily login bonus of crystals.

local DailyBonusSystem = {}

local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local DataPersistenceSystem = require(script.Parent:WaitForChild("DataPersistenceSystem"))

---Timestamp of the last claimed bonus (Unix epoch seconds).
DailyBonusSystem.lastClaim = 0

---Amount of crystals awarded per day.
DailyBonusSystem.bonusAmount = 2

---Checks whether a new daily bonus can be claimed.
-- @return boolean true if claimBonus should succeed
function DailyBonusSystem:canClaim()
    local now = os.time()
    local lastDay = os.date("*t", self.lastClaim).yday
    local currentDay = os.date("*t", now).yday
    return currentDay ~= lastDay or (now - self.lastClaim) > 86400
end

---Grants the daily bonus when available.
-- @return boolean true when a bonus was claimed
function DailyBonusSystem:claimBonus()
    if not self:canClaim() then
        return false
    end
    self.lastClaim = os.time()
    GachaSystem:addCrystals(self.bonusAmount)
    return true
end

---Serializes the bonus claim timestamp.
function DailyBonusSystem:saveData()
    return {lastClaim = self.lastClaim}
end

---Loads saved state for the bonus system.
function DailyBonusSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.lastClaim) == "number" then
        self.lastClaim = data.lastClaim
    end
end

return DailyBonusSystem

