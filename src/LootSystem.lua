-- Awards currency, experience, ether and gauge points when enemies are defeated.

local LootSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))

local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem"))
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
local RewardGaugeSystem = require(script.Parent:WaitForChild("RewardGaugeSystem"))
local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))
local LocationSystem = require(script.Parent:WaitForChild("LocationSystem"))
local AchievementSystem = require(script.Parent:WaitForChild("AchievementSystem"))

-- Exposed reward tables for referencing from UI modules.
local rewards = {
    normal   = {coins = 1,   exp = 5,   gauge = 10, ether = 0, crystals = 0},
    mini     = {coins = 5,   exp = 20,  gauge = 20, ether = 1, crystals = 1},
    boss     = {coins = 10,  exp = 50,  gauge = 30, ether = 2, crystals = 2},
    location = {coins = 20,  exp = 100, gauge = 50, ether = 3, crystals = 3},
}
function LootSystem:start()
    EventManager:Get("EnemyDefeated"):Connect(function(enemy)
        LootSystem:onEnemyKilled(enemy)
    end)
end

---Returns the reward table for the given enemy type.
-- @param enemyType string type key such as "normal", "mini", "boss", "location"
-- @return table reward information
function LootSystem.getRewardInfo(enemyType)
    return rewards[enemyType or "normal"] or rewards.normal
end

--Returns the currency key for the current location.
local function getCurrencyType()
    local loc = LocationSystem:getCurrent()
    if loc and loc.currency then
        return loc.currency
    end
    return "gold"
end

---Public wrapper returning the currency type for the active location.
function LootSystem.getCurrencyType()
    return getCurrencyType()
end


---Grants loot when an enemy is killed.
-- @param enemy table enemy data (may include ``type`` field)
function LootSystem:onEnemyKilled(enemy)
    enemy = enemy or {}
    local r = rewards[enemy.type or "normal"] or rewards.normal
    local lvl = LevelSystem.currentLevel or 1
    local currency = getCurrencyType()

    CurrencySystem:add(currency, r.coins * lvl)
    if r.ether and r.ether > 0 then
        CurrencySystem:add("ether", r.ether)
    end
    if r.crystals and r.crystals > 0 then
        GachaSystem:addCrystals(r.crystals)
    end
    PlayerLevelSystem:addExperience(r.exp)
    RewardGaugeSystem:addPoints(r.gauge)
    AchievementSystem:addProgress("kills", 1)
    EventManager:Get("EnemyKilled"):Fire(enemy)
    if enemy.type == "boss" or enemy.type == "location" then
        EventManager:Get("BossKilled"):Fire(enemy)
    end
end

return LootSystem
