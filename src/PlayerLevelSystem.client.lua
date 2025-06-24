-- PlayerLevelSystem.client.lua
-- Client-side interface for tracking player levels without server-only logic.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("PlayerLevelSystem client module should only be required on the client", 2)
end

local PlayerLevelSystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))
-- Use the client wrapper so no server-only methods are exposed
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))

PlayerLevelSystem.level = 1
PlayerLevelSystem.exp = 0
PlayerLevelSystem.nextExp = 100
PlayerLevelSystem.unlocked = {}

function PlayerLevelSystem:start()
    NetworkSystem:onClientEvent("PlayerLevelUpdate", function(lvl, xp, nextXp)
        if type(lvl) == "number" then self.level = lvl end
        if type(xp) == "number" then self.exp = xp end
        if type(nextXp) == "number" then self.nextExp = nextXp end
    end)
    local ev = EventManager:Get("PlayerLevelUp")
    if ev and ev.Connect then
        -- ensure event exists so UI can react to level ups
    end
end

function PlayerLevelSystem:isUnlocked(key)
    for _, k in ipairs(self.unlocked) do
        if k == key then
            return true
        end
    end
    return false
end

function PlayerLevelSystem:getExpPercent()
    if self.nextExp <= 0 then
        return 0
    end
    return self.exp / self.nextExp
end

function PlayerLevelSystem:saveData()
    return {
        level = self.level,
        exp = self.exp,
        nextExp = self.nextExp,
        unlocked = self.unlocked,
    }
end

function PlayerLevelSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.level) == "number" then self.level = data.level end
    if type(data.exp) == "number" then self.exp = data.exp end
    if type(data.nextExp) == "number" then self.nextExp = data.nextExp end
    if type(data.unlocked) == "table" then
        self.unlocked = {}
        for i, v in ipairs(data.unlocked) do
            self.unlocked[i] = v
        end
    end
end

return PlayerLevelSystem
