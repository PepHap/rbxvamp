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
        ClientGameManager[k] = v
    end
end

return ClientGameManager
