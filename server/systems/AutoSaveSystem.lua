-- AutoSaveSystem.lua
-- Periodically saves player data using DataPersistenceSystem.

local RunService = game:GetService("RunService")
-- This system writes to DataStore and should run server-side only:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("AutoSaveSystem should only be required on the server", 2)
    end
end

local AutoSaveSystem = {
    ---Time in seconds between automatic saves.
    interval = 60,
    ---Timer accumulating time since the last save.
    timer = 0,
    ---Player identifier used for saving.
    playerId = nil,
    ---Callback returning a data table to persist.
    getData = nil,
    ---Reference to the DataPersistenceSystem instance.
    saveSystem = nil,
}

---Initializes the auto save system.
-- @param saveSystem table DataPersistenceSystem-like object
-- @param playerId any player identifier
-- @param dataProvider function function returning data table
function AutoSaveSystem:start(saveSystem, playerId, dataProvider)
    self.saveSystem = saveSystem
    self.playerId = playerId
    self.getData = dataProvider
    self.timer = 0
end

---Immediately saves using the configured provider.
function AutoSaveSystem:forceSave()
    if not (self.saveSystem and self.playerId and self.getData) then
        return false
    end
    self.saveSystem:save(self.playerId, self.getData())
    self.timer = 0
    return true
end

---Updates the timer and triggers a save when the interval elapses.
-- @param dt number delta time
function AutoSaveSystem:update(dt)
    if not (self.saveSystem and self.playerId and self.getData) then
        return
    end
    self.timer = self.timer + dt
    if self.timer >= self.interval then
        self:forceSave()
    end
end

return AutoSaveSystem

