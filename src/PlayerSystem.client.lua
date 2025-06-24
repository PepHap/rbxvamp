-- ClientPlayerSystem.lua
-- Provides a client-safe subset of PlayerSystem without server-only methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("PlayerSystem.client should only be required on the client", 2)
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local NetworkSystem = require(script.Parent:WaitForChild("NetworkClient"))

local PlayerSystem = {
    spawnModels = true,
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    position = {x = 0, y = 0, z = 0},
    model = nil,
    maxHealth = 100,
    health = 100,
}

local function createVector3(x, y, z)
    local ok, ctor = pcall(function()
        return Vector3.new
    end)
    if ok and type(ctor) == "function" then
        return ctor(x, y, z)
    end
    return {x = x, y = y, z = z}
end

local function spawnModel()
    if PlayerSystem.spawnModels == false then
        return nil
    end
    if PlayerSystem.useRobloxObjects and game then
        local ok, players = pcall(function()
            return game:GetService("Players")
        end)
        if ok and players and players.LocalPlayer then
            local character = players.LocalPlayer.Character or players.LocalPlayer.CharacterAdded:Wait()
            PlayerSystem.model = character
            local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
            if hrp and hrp.Position then
                local pos = hrp.Position
                PlayerSystem.position = {x = pos.X, y = pos.Y, z = pos.Z}
            end
            return character
        end
    end
    local model = {
        primaryPart = {position = {x = PlayerSystem.position.x, y = PlayerSystem.position.y, z = PlayerSystem.position.z}},
    }
    PlayerSystem.model = model
    return model
end

function PlayerSystem:start()
    self.health = self.maxHealth
    if self.spawnModels ~= false and not self.model then
        spawnModel()
    end
    NetworkSystem:onClientEvent("PlayerState", function(h, pos)
        if type(h) == "number" then
            self.health = h
        end
        if type(pos) == "table" then
            self.position.x = pos.x or 0
            self.position.y = pos.y or 0
            self.position.z = pos.z or 0
        end
    end)
end

function PlayerSystem:update(dt)
    if not self.useRobloxObjects then
        return
    end
    local model = self.model
    if model and model.Parent then
        local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if hrp and hrp.Position then
            local pos = hrp.Position
            self.position.x = pos.X
            self.position.y = pos.Y
            self.position.z = pos.Z
        end
    end
end

function PlayerSystem:saveData()
    return {
        health = self.health,
        maxHealth = self.maxHealth,
        position = {x = self.position.x, y = self.position.y, z = self.position.z},
    }
end

function PlayerSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.health) == "number" then self.health = data.health end
    if type(data.maxHealth) == "number" then self.maxHealth = data.maxHealth end
    if type(data.position) == "table" then
        self.position.x = data.position.x or 0
        self.position.y = data.position.y or 0
        self.position.z = data.position.z or 0
    end
end

function PlayerSystem:getHealthPercent()
    if self.maxHealth <= 0 then return 0 end
    return self.health / self.maxHealth
end

return PlayerSystem
