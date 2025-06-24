-- ProgressMapSystem.lua
-- Tracks highest reached location and stage for display purposes.

local ProgressMapSystem = {
    locationSystem = nil,
    levelSystem = nil,
    progress = {location = 1, stage = 1}
}

local EventManager = require(script.Parent:WaitForChild("EventManager"))
local RunService = game:GetService("RunService")

function ProgressMapSystem:start(locSys, lvlSys)
    self.locationSystem = locSys or self.locationSystem or require(script.Parent:WaitForChild("LocationSystem"))
    if RunService and RunService:IsClient() then
        self.levelSystem = lvlSys or self.levelSystem or require(script.Parent:WaitForChild("ClientLevelSystem"))
    else
        self.levelSystem = lvlSys or self.levelSystem or require(script.Parent:WaitForChild("LevelSystem"))
    end
    self.progress.location = self.locationSystem.currentIndex
    self.progress.stage = self.levelSystem.currentLevel
    EventManager:Get("LevelAdvance"):Connect(function(lvl)
        if lvl > self.progress.stage then
            self.progress.stage = lvl
            if lvl % 30 == 1 then
                self.progress.location = self.locationSystem.currentIndex
            end
        end
    end)
end

function ProgressMapSystem:getProgress()
    return {location = self.progress.location, stage = self.progress.stage}
end

return ProgressMapSystem
