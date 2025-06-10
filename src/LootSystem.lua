-- LootSystem.lua
-- Awards currency, experience and gauge points when enemies are defeated.

local LootSystem = {}

local CurrencySystem = require("src.CurrencySystem")
local PlayerLevelSystem = require("src.PlayerLevelSystem")
local RewardGaugeSystem = require("src.RewardGaugeSystem")
local LevelSystem = require("src.LevelSystem")
local LocationSystem = require("src.LocationSystem")

---Returns the currency key for the current location.
local function getCurrencyType()
    local loc = LocationSystem:getCurrent()
    if loc and loc.currency then
        return loc.currency
    end
    return "gold"
end

---Internal helper applying rewards based on enemy type.
local rewards = {
    normal   = {coins = 1,   exp = 5,   gauge = 10},
    mini     = {coins = 5,   exp = 20,  gauge = 20},
    boss     = {coins = 10,  exp = 50,  gauge = 30},
    location = {coins = 20,  exp = 100, gauge = 50},
}

---Grants loot when an enemy is killed.
-- @param enemy table enemy data (may include ``type`` field)
function LootSystem:onEnemyKilled(enemy)
    enemy = enemy or {}
    local r = rewards[enemy.type or "normal"] or rewards.normal
    local lvl = LevelSystem.currentLevel or 1
    local currency = getCurrencyType()

    CurrencySystem:add(currency, r.coins * lvl)
    PlayerLevelSystem:addExperience(r.exp)
    RewardGaugeSystem:addPoints(r.gauge)
end

return LootSystem
