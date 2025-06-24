-- ClientGameManager.lua
-- Provides a client-safe interface that excludes server-only methods.

local RunService = game:GetService("RunService")
-- Ensure this module is only required by the client
if RunService:IsServer() then
    error("ClientGameManager should not be required on the server", 2)
end

local GameManager = require(script.Parent:WaitForChild("GameManager"))

-- List of functions that should not be exposed to the client
local serverOnly = {
    rollSkill = true,
    rollCompanion = true,
    rollEquipment = true,
    addRewardPoints = true,
    getGaugePercent = true,
    getLevelPercent = true,
    getRewardOptions = true,
    chooseReward = true,
    rerollRewardOptions = true,
    resetRewardGauge = true,
    setGaugeThreshold = true,
    setGaugeOptionCount = true,
    setGaugeRerollCost = true,
    buyTickets = true,
    buyCurrency = true,
    upgradeItemWithCrystals = true,
    startDungeon = true,
    getSaveData = true,
    applySaveData = true,
    salvageInventoryItem = true,
    salvageEquippedItem = true,
    createParty = true,
    joinParty = true,
    leaveParty = true,
    startRaid = true,
    loadPlayerData = true,
    savePlayerData = true,
    startAutoSave = true,
    forceAutoSave = true,
}

-- Create a sanitized copy of GameManager without server-only members
local ClientGameManager = {}
for k, v in pairs(GameManager) do
    if not serverOnly[k] then
        if k == "systems" and type(v) == "table" then
            ClientGameManager.systems = {}
            for name, sys in pairs(v) do
                ClientGameManager.systems[name] = sys
            end
        else
            ClientGameManager[k] = v
        end
    end
end
ClientGameManager.systems = ClientGameManager.systems or {}
ClientGameManager.systems.Quest = require(script.Parent:WaitForChild("ClientQuestSystem"))

---Applies persistent data from the server to the local systems.
-- This mirrors ``applySaveData`` on the server but excludes
-- any server-only logic. Client code can safely call this
-- to initialize UI with the player's saved progress.
-- https://create.roblox.com/docs/reference/engine/classes/Player
function ClientGameManager:applyClientData(data)
    if type(data) ~= "table" then return end
    local CurrencySystem = require(script.Parent:WaitForChild("CurrencySystem.client"))
    local GachaSystem = require(script.Parent:WaitForChild("ClientGachaSystem"))
    local ItemSystem = require(script.Parent:WaitForChild("ItemSystem"))
    local PlayerLevelSystem = require(script.Parent:WaitForChild("PlayerLevelSystem"))
    local LevelSystem = require(script.Parent:WaitForChild("ClientLevelSystem"))
    local KeySystem = require(script.Parent:WaitForChild("KeySystem"))
    local RewardGaugeSystem = require(script.Parent:WaitForChild("ClientRewardGaugeSystem"))
    local AchievementSystem = require(script.Parent:WaitForChild("AchievementSystem"))
    local DailyBonusSystem = require(script.Parent:WaitForChild("DailyBonusSystem"))
    local QuestSystem = require(script.Parent:WaitForChild("ClientQuestSystem"))
    local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))

    CurrencySystem:loadData(data.currency)
    GachaSystem:loadData(data.gacha)
    local newItems = ItemSystem.fromData(data.items or {})
    self.itemSystem = newItems
    if self.inventory then
        self.inventory.itemSystem = newItems
    end
    if self.setBonusSystem then
        self.setBonusSystem.itemSystem = newItems
    end
    self.skillSystem:loadData(data.skills)
    self.companionSystem:loadData(data.companions)
    StatUpgradeSystem:loadData(data.stats)
    PlayerLevelSystem:loadData(data.playerLevel)
    LevelSystem:loadData(data.levelState)
    KeySystem:loadData(data.keys)
    RewardGaugeSystem:loadData(data.rewardGauge)
    AchievementSystem:loadData(data.achievements)
    DailyBonusSystem:loadData(data.dailyBonus)
    QuestSystem:loadData(data.quests)
end

return ClientGameManager
