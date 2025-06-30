-- PlayerInputSystem.lua
-- Allows manual player control and attacks when auto-battle is disabled.
local RunService = game:GetService("RunService")
if RunService:IsClient() then
    error("PlayerInputSystem server module should only be required on the server", 2)
end


local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local PlayerInputSystem = {
    ---When true and running inside Roblox, connects to UserInputService.
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    ---Movement speed in studs per second.
    moveSpeed = 5,
    ---Damage dealt per manual attack.
    damage = 1,
    ---Maximum distance at which a manual attack can hit.
    attackRange = 5,
    ---Table of currently held keys.
    keyStates = {},
    ---Reference to the player's position table.
    playerPosition = nil,
    ---Reference to the SkillCastSystem for manual skill use.
    skillCastSystem = nil,
    ---Mapping from key names to skill slots.
    skillKeyMap = {One = 1, Two = 2, Three = 3, Four = 4},
}

local PlayerSystem
if RunService:IsServer() then
    PlayerSystem = require(script.Parent.Parent:WaitForChild("server"):WaitForChild("ServerPlayerSystem"))
else
    PlayerSystem = require(script.Parent:WaitForChild("PlayerSystem"))
end
local NetworkSystem = require(script.Parent:WaitForChild("NetworkServer"))
local AutoBattleSystem = require(script.Parent:WaitForChild("AutoBattleSystem"))
local SkillCastSystem
if RunService:IsServer() then
    local serverFolder = script.Parent.Parent:WaitForChild("server"):WaitForChild("systems")
    SkillCastSystem = require(serverFolder:WaitForChild("SkillCastSystem"))
end
local StatUpgradeSystem = require(script.Parent:WaitForChild("StatUpgradeSystem"))
local LobbySystem = require(script.Parent:WaitForChild("LobbySystem"))


-- Utility to connect Roblox input events when available
local function connectRoblox()
    if not PlayerInputSystem.useRobloxObjects then
        return
    end
    if game and type(game.GetService) == "function" then
        local ok, UIS = pcall(function()
            return game:GetService("UserInputService")
        end)
        if ok and UIS then
            UIS.InputBegan:Connect(function(input)
                local name = input.KeyCode.Name
                PlayerInputSystem:setKeyState(name, true)
            end)
            UIS.InputEnded:Connect(function(input)
                PlayerInputSystem:setKeyState(input.KeyCode.Name, false)
            end)
            if UIS.TouchTap then
                UIS.TouchTap:Connect(function(_, processed)
                    if not processed then
                        PlayerInputSystem:manualAttack()
                    end
                end)
            end
        end
    end
end

---Initializes the input system.
function PlayerInputSystem:start()
    self.playerPosition = PlayerSystem.position
    self.skillCastSystem = self.skillCastSystem or SkillCastSystem
    connectRoblox()
end

---Sets the state of a key for manual control.
-- @param key string key code name
-- @param isDown boolean whether the key is pressed
function PlayerInputSystem:setKeyState(key, isDown)
    self.keyStates[key] = isDown and true or false
    if isDown and self.skillCastSystem then
        local idx = self.skillKeyMap[key]
        if idx then
            NetworkSystem:fireServer("SkillRequest", idx)
        end
    end
end

---Performs a manual attack against the nearest enemy.
function PlayerInputSystem:manualAttack()

    NetworkSystem:fireServer("AttackRequest")

    if NetworkSystem and NetworkSystem.fireServer then
        NetworkSystem:fireServer("PlayerAttack")
    end

end

---Updates the player position and handles attack input.
function PlayerInputSystem:update(dt)
    if AutoBattleSystem.enabled then
        return
    end
    local pos = self.playerPosition
    local speed = 1
    local sStat = StatUpgradeSystem.stats and StatUpgradeSystem.stats.Speed
    if sStat then
        speed = (sStat.base or 1) * (sStat.level or 1)
    end
    local step = self.moveSpeed * speed * dt
    if self.keyStates.D or self.keyStates.Right then
        pos.x = pos.x + step
    end
    if self.keyStates.A or self.keyStates.Left then
        pos.x = pos.x - step
    end
    if self.keyStates.W or self.keyStates.Up then
        pos.y = pos.y + step
    end
    if self.keyStates.S or self.keyStates.Down then
        pos.y = pos.y - step
    end
    if self.keyStates.Space then
        self:manualAttack()
        self.keyStates.Space = false
    end
end

return PlayerInputSystem

