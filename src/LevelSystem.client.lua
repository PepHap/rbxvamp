-- LevelSystem.client.lua
-- Client wrapper around LevelSystem removing server-only functions.
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
