-- AntiCheatSystem.lua
-- Basic server-side checks for suspicious behavior.

local AntiCheatSystem = {
    expPerMinute = 1000,
    currencyPerMinute = 1000,
    minAttackInterval = 0.2,
    maxMoveSpeed = 50,
    players = {},
    connections = {}
}

local RunService = game:GetService("RunService")
local LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))

local function getId(player)
    if typeof and typeof(player) == "Instance" and player.UserId then
        return player.UserId
    end
    return 0
end

function AntiCheatSystem:getRecord(player)
    local id = getId(player)
    local rec = self.players[id]
    if not rec then
        rec = {exp = 0, currency = 0, lastReset = os.clock(), lastAttack = 0, lastPos = nil, lastTime = os.clock()}
        self.players[id] = rec
    end
    local now = os.clock()
    if now - rec.lastReset >= 60 then
        rec.exp = 0
        rec.currency = 0
        rec.lastReset = now
    end
    return rec
end

function AntiCheatSystem:recordExp(player, amount)
    local rec = self:getRecord(player)
    rec.exp = rec.exp + (tonumber(amount) or 0)
    if rec.exp > self.expPerMinute then
        warn("Suspicious EXP gain", player)
        if LoggingSystem and LoggingSystem.logAction then
            LoggingSystem:logAction("exp_suspicious", {
                player = getId(player),
                value = rec.exp
            })
        end
    end
end

function AntiCheatSystem:recordCurrency(player, amount)
    local rec = self:getRecord(player)
    rec.currency = rec.currency + (tonumber(amount) or 0)
    if rec.currency > self.currencyPerMinute then
        warn("Suspicious currency gain", player)
        if LoggingSystem and LoggingSystem.logAction then
            LoggingSystem:logAction("currency_suspicious", {
                player = getId(player),
                value = rec.currency
            })
        end
    end
end

function AntiCheatSystem:recordAttack(player)
    local rec = self:getRecord(player)
    local now = os.clock()
    if now - rec.lastAttack < self.minAttackInterval then
        warn("Suspicious attack rate", player)
        if LoggingSystem and LoggingSystem.logAction then
            LoggingSystem:logAction("attack_rate", {
                player = getId(player)
            })
        end
    end
    rec.lastAttack = now
end

function AntiCheatSystem:checkMovement(player, position)
    local rec = self:getRecord(player)
    if not position then return end
    local now = os.clock()
    if rec.lastPos then
        local dx = position.x - rec.lastPos.x
        local dy = position.y - rec.lastPos.y
        local dz = position.z - rec.lastPos.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        local dt = now - rec.lastTime
        if dt > 0 and dist / dt > self.maxMoveSpeed then
            warn("Possible teleport detected", player)
            if LoggingSystem and LoggingSystem.logAction then
                LoggingSystem:logAction("movement_speed", {
                    player = getId(player),
                    speed = dist / dt
                })
            end
        end
    end
    rec.lastPos = {x = position.x, y = position.y, z = position.z}
    rec.lastTime = now
end

function AntiCheatSystem:update(dt)
    -- currently no periodic logic
end

function AntiCheatSystem:start()
    if not RunService:IsServer() then
        return
    end
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok or not players then
        return
    end
    self.connections.heartbeat = RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(players:GetPlayers()) do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                self:checkMovement(plr, {x = pos.X, y = pos.Y, z = pos.Z})
            end
        end
    end)
end

return AntiCheatSystem
