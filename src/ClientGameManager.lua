-- ClientGameManager.lua
-- Provides a client-safe interface that excludes server-only methods.

local GameManager = require(script.Parent:WaitForChild("GameManager"))

local ClientGameManager = {}

-- Methods that should only exist on the server and therefore are
-- removed from the client interface.
local serverOnly = {
    salvageInventoryItem = true,
    salvageEquippedItem = true,
    createParty = true,
    joinParty = true,
    leaveParty = true,
    startRaid = true,
    startDungeon = true,
    loadPlayerData = true,
    savePlayerData = true,
    startAutoSave = true,
    forceAutoSave = true,
    rollSkill = true,
    rollCompanion = true,
    rollEquipment = true,
    addRewardPoints = true,
    chooseReward = true,
    rerollRewardOptions = true,
    resetRewardGauge = true,
    setGaugeThreshold = true,
    setGaugeOptionCount = true,
    setGaugeRerollCost = true,
    buyTickets = true,
    buyCurrency = true,
    upgradeItemWithCrystals = true,
    getSaveData = true,
}

for k, v in pairs(GameManager) do
    if not serverOnly[k] then
        ClientGameManager[k] = v
    end
end

return ClientGameManager
