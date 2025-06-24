-- ClientLevelSystem.lua
-- Client-safe wrapper around LevelSystem without server-only methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientLevelSystem should only be required on the client", 2)
end

local LevelSystem = require(script.Parent:WaitForChild("LevelSystem"))

local blacklist = {
    start = true,
    scaleStats = true,
    strengthenMonsters = true,
    checkAdvance = true,
    addKill = true,
    update = true,
    advance = true,
    onPlayerDeath = true,
}

local ClientLevelSystem = {}
for k, v in pairs(LevelSystem) do
    if not blacklist[k] then
        ClientLevelSystem[k] = v
    end
end

return ClientLevelSystem
