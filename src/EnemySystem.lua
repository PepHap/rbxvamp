-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local RunService = game:GetService("RunService")
-- Server-only module guard per Roblox guidelines:
-- https://create.roblox.com/docs/reference/engine/classes/RunService#IsServer
if RunService and RunService.IsClient and RunService.IsServer then
    if RunService:IsClient() then
        error("EnemySystem should only be required on the server", 2)
    end
end

local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local EnemySystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))

-- Resolve other module paths relative to how this module was required so that
-- tests using relative paths function correctly.
-- Parent folder reference for requiring sibling modules when running
-- inside Roblox Studio.
local parent = script.Parent

local MobConfig = require(parent:WaitForChild("MobConfig"))
local LocationSystem = require(parent:WaitForChild("LocationSystem"))
local NetworkSystem = require(parent:WaitForChild("NetworkSystem"))

-- Lazily required to avoid circular dependency with AutoBattleSystem
local AutoBattleSystem
local PlayerSystem

-- Simple stub for Roblox's PathfindingService used in the test environment.
local PathfindingServiceStub = {}
function PathfindingServiceStub:CreatePath()
    local points
    return {
        ComputeAsync = function(_, startPos, endPos)
            points = {startPos, endPos}
        end,
        GetWaypoints = function()
            return points or {}
        end
    }
end

-- Multipliers applied to all enemy health and damage values. These start at
-- ``1`` so that base stats are unchanged until modified by other systems.
EnemySystem.healthScale = 1
EnemySystem.damageScale = 1

---Indicates whether enemy Roblox models should be spawned. Tests can disable
--  this to avoid creating placeholder instances.
EnemySystem.spawnModels = true

---When enabled the system will attempt to create real Roblox Instances rather
--  than simple Lua tables. This is disabled during unit tests where the Roblox
--  APIs are unavailable.
EnemySystem.useRobloxObjects = EnvironmentUtil.detectRoblox()

---Movement speed in studs per second used when advancing along a path.
EnemySystem.moveSpeed = 1

---Distance within which enemies can damage the player.
EnemySystem.attackRange = 2

---Delay between successive enemy attacks in seconds.
EnemySystem.attackCooldown = 1

---Additional difficulty applied for each extra player in the server.
--  Follows the design guidance of roughly ``30%`` per member.
EnemySystem.playerScaleFactor = 0.3

---Calculates a scale multiplier based on the number of players currently
--  in the game. When the ``Players`` service is unavailable this returns ``1``.
--  @return number difficulty scale
local function getPlayerScale()
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if ok and players and players.GetPlayers then
        local count = #players:GetPlayers()
        if count > 1 then
            return 1 + (count - 1) * (EnemySystem.playerScaleFactor or 0.3)
        end
    end
    return 1
end

---Returns the appropriate pathfinding service depending on environment.
local function getPathfindingService()
    if EnemySystem.useRobloxObjects and game ~= nil and type(game.GetService) == "function" then
        local ok, service = pcall(function()
            return game:GetService("PathfindingService")
        end)
        if ok and service then
            return service
        end
    end
    return PathfindingServiceStub
end

---Utility converting coordinates into ``Vector3`` values when available.
local function createVector3(x, y, z)
    local ok, ctor = pcall(function()
        return Vector3.new
    end)
    if ok and type(ctor) == "function" then
        return ctor(x, y, z)
    end
    return {x = x, y = y, z = z}
end

---Extracts ``x``, ``y`` and ``z`` fields from either a ``Vector3`` or table.
local function getCoords(v)
    if type(v) == "table" then
        if v.X then
            return v.X, v.Y, v.Z
        else
            return v.x, v.y, v.z
        end
    end
    return 0, 0, 0
end

---Returns the coordinate offset for the current location.
local function getSpawnOffset()
    local loc = LocationSystem and LocationSystem.getCurrent and LocationSystem:getCurrent()
    if loc and loc.coordinates then
        return loc.coordinates
    end
    return {x = 0, y = 0, z = 0}
end


---Utility to create a basic enemy table. The returned table describes the
--  enemy's health, damage, current position and optional type string.
--  @param health number
--  @param damage number
--  @param position table table containing x/y/z coordinates
--  @param enemyType string|nil classification such as "mini" or "boss"
--  @param name string display name for this enemy
--  @return table new enemy object
local function createEnemy(health, damage, position, enemyType, name, prefab, level, armor, behavior)
    return {
        health = health,
        maxHealth = health,
        damage = damage,
        position = position,
        type = enemyType,
        name = name,
        prefab = prefab,
        level = level or 1,
        armor = armor or 0,
        maxArmor = armor or 0,
        behavior = behavior,
        attackCooldown = EnemySystem.attackCooldown,
        attackTimer = 0
    }
end

---Creates a placeholder Roblox model for the enemy at its position. In this
--  simplified environment a model is represented by a table containing a
--  single part positioned at ``enemy.position``.
--  @param enemy table enemy data
--  @return table model table assigned to ``enemy.model``
local function spawnModel(enemy)
    -- When running inside Roblox and ``useRobloxObjects`` is enabled we create
    -- real Instances and parent them to Workspace. Unit tests fall back to a
    -- lightweight table representation so they can run without the Roblox APIs.
    if EnemySystem.useRobloxObjects and Instance ~= nil and game ~= nil then
        local success, workspaceService = pcall(function()
            return game:GetService("Workspace")
        end)
        if success and workspaceService then
            local ss = game:GetService("ServerStorage")
            local mobsFolder = ss and ss:FindFirstChild("Mobs")
            local prefab
            if mobsFolder then
                prefab = mobsFolder:FindFirstChild(enemy.prefab or "")
            end

            local model
            if prefab and prefab.Clone then
                model = prefab:Clone()
                model.Name = enemy.name
                model.Parent = workspaceService
                if model.PrimaryPart then
                    local ok, vectorCtor = pcall(function()
                        return Vector3.new
                    end)
                    local pos = ok and vectorCtor(enemy.position.x, enemy.position.y, enemy.position.z)
                        or {x = enemy.position.x, y = enemy.position.y, z = enemy.position.z}
                    if model.SetPrimaryPartCFrame then
                        local ok2, cframeCtor = pcall(function()
                            return CFrame.new
                        end)
                        if ok2 and type(cframeCtor) == "function" then
                            model:SetPrimaryPartCFrame(cframeCtor(pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z))
                        end
                    elseif model.PrimaryPart.Position then
                        model.PrimaryPart.Position = pos
                    end
                end
            else
                model = Instance.new("Model")
                model.Name = enemy.name
                local part = Instance.new("Part")
                part.Name = enemy.name .. "Part"
                local ok, vectorCtor = pcall(function()
                    return Vector3.new
                end)
                if ok and type(vectorCtor) == "function" then
                    part.Position = vectorCtor(enemy.position.x, enemy.position.y, enemy.position.z)
                else
                    part.Position = {x = enemy.position.x, y = enemy.position.y, z = enemy.position.z}
                end
                part.Parent = model
                model.PrimaryPart = part
                local billboardGui = Instance.new("BillboardGui")
                billboardGui.Adornee = part
                local textLabel = Instance.new("TextLabel")
                textLabel.Text = enemy.name .. " Lv." .. tostring(enemy.level or 1)
                textLabel.Parent = billboardGui
                local healthBar = Instance.new("Frame")
                healthBar.Name = "HealthBar"
                healthBar.Parent = billboardGui
                local armorBar
                if enemy.armor and enemy.armor > 0 then
                    armorBar = Instance.new("Frame")
                    armorBar.Name = "ArmorBar"
                    armorBar.Parent = billboardGui
                end
                billboardGui.Parent = model
                if EnemySystem.useRobloxObjects then
                    enemy.billboardGui = {textLabel = textLabel, healthBar = healthBar, armorBar = armorBar}
                else
                    model.billboardGui = {textLabel = textLabel, healthBar = healthBar, armorBar = armorBar}
                end
                model.Parent = workspaceService
            end
            enemy.model = model
            return model
        end
    end

    -- Fallback table representation used during tests
    local model = {
        primaryPart = {
            position = {x = enemy.position.x, y = enemy.position.y, z = enemy.position.z}
        }
    }
    model.billboardGui = {
        adornee = model.primaryPart,
        textLabel = {text = enemy.name .. " Lv." .. tostring(enemy.level or 1)},
        healthBar = {value = enemy.health, max = enemy.maxHealth}
    }
    if enemy.armor and enemy.armor > 0 then
        model.billboardGui.armorBar = {value = enemy.armor, max = enemy.maxArmor}
    end
    enemy.model = model
    return model
end

---List of currently active enemies in the world.
EnemySystem.enemies = {}

---Last level used when spawning a wave.
EnemySystem.lastWaveLevel = nil

---Last boss type that was spawned.
EnemySystem.lastBossType = nil

---Creates and inserts an enemy of the given mob type.
-- @param mobType string key from MobConfig.Types
-- @param level number stage level used for scaling
-- @return table new enemy
function EnemySystem:createEnemyByType(mobType, level, position)
    local cfg = MobConfig.Types[mobType]
    if not cfg then
        return nil
    end
    local scale = getPlayerScale()
    local hScale = (self.healthScale or 1) * (MobConfig.LevelMultiplier.Health ^ (level - 1)) * scale
    local dScale = (self.damageScale or 1) * (MobConfig.LevelMultiplier.Damage ^ (level - 1)) * scale
    local enemy = createEnemy(
        cfg.BaseHealth * hScale,
        cfg.Damage * dScale,
        position or {x = 0, y = 0, z = 0},
        nil,
        mobType,
        cfg.Prefab or mobType,
        level,
        0,
        nil
    )
    if self.spawnModels ~= false then
        spawnModel(enemy)
    end
    table.insert(self.enemies, enemy)
    NetworkSystem:fireAllClients("EnemySpawn", enemy.name, enemy.position, mobType)
    return enemy
end

---Spawns enemies based on a configuration table.
-- ``wave`` should be an array of {type=string, count=number} tables.
function EnemySystem:spawnWaveForLevel(level, wave)
    self.lastWaveLevel = level
    self.enemies = {}
    local offset = getSpawnOffset()
    if type(wave) == "table" then
        for _, info in ipairs(wave) do
            for i = 1, (info.count or 1) do
                local pos = {x = offset.x + i, y = offset.y, z = offset.z}
                local enemy = self:createEnemyByType(info.type, level, pos)
            end
        end
    end
    if #self.enemies == 0 then
        -- fall back to default behaviour
        self:spawnWave(level)
    end
    EventManager:Get("SpawnWave"):Fire(level, #self.enemies)
end

---Returns the nearest enemy to the given position.
-- @param position table with ``x`` and ``y`` keys
-- @return table|nil enemy table or ``nil`` when none exist
function EnemySystem:getNearestEnemy(position)
    local closest, minDistSq
    for _, enemy in ipairs(self.enemies) do
        -- Use the enemy's position field for distance calculations
        local dx = enemy.position.x - position.x
        local dy = enemy.position.y - position.y
        local distSq = dx * dx + dy * dy
        if not closest or distSq < minDistSq then
            closest = enemy
            minDistSq = distSq
        end
    end
    return closest
end

---Creates a wave of enemies scaled by the provided level.
--- @param level number strength of the wave
--- @param count number how many enemies to spawn (defaults to ``level``)
function EnemySystem:spawnWave(level, count)
    self.lastWaveLevel = level
    self.enemies = {}

    count = count or level

    local baseHealth = 10
    -- Increase enemy health more aggressively as the level rises to
    -- keep pace with player power growth.
    local healthPerLevel = 10
    local baseDamage = 1
    local damagePerLevel = 1

    local scale = getPlayerScale()
    local hScale = (self.healthScale or 1) * scale
    local dScale = (self.damageScale or 1) * scale

    local function pickBehavior(lvl)
        if lvl >= 15 then
            return "shoot"
        elseif lvl >= 10 then
            return "jump"
        elseif lvl >= 8 then
            return "ranged"
        elseif lvl >= 5 then
            return "fast"
        end
        return nil
    end

    local offset = getSpawnOffset()
    for i = 1, count do
        local armor = math.floor(level / 5)
        local enemy = createEnemy(
            (baseHealth + healthPerLevel * level) * hScale,
            (baseDamage + damagePerLevel * level) * dScale,
            {x = offset.x + i, y = offset.y, z = offset.z},
            nil,
            string.format("Enemy %d", i),
            "Goblin",
            level,
            armor,
            pickBehavior(level)
        )
        if self.spawnModels ~= false then
            spawnModel(enemy)
        end
        table.insert(self.enemies, enemy)
        NetworkSystem:fireAllClients("EnemySpawn", enemy.name, enemy.position, "Goblin")
    end
    EventManager:Get("SpawnWave"):Fire(level, count)
end

---Spawns a boss of the given type.
-- @param bossType string type identifier (e.g. "mini" or "boss")
function EnemySystem:spawnBoss(bossType)
    self.lastBossType = bossType
    self.enemies = {}

    local bossHealth = {
        mini = 50,
        boss = 100,
        location = 150
    }

    local bossDamage = {
        mini = 5,
        boss = 10,
        location = 15
    }

    local scale = getPlayerScale()
    local hScale = (self.healthScale or 1) * scale
    local dScale = (self.damageScale or 1) * scale

    local bossNames = {
        mini = "Mini Boss",
        boss = "Boss",
        location = "Location Boss"
    }
    local prefabMap = {mini = "Ogre", boss = "Dragon", location = "Dragon"}
    local offset = getSpawnOffset()
    local armorValues = {mini = 5, boss = 10, location = 20}
    local boss = createEnemy(
        (bossHealth[bossType] or 20) * hScale,
        (bossDamage[bossType] or 2) * dScale,
        {x = offset.x, y = offset.y, z = offset.z},
        bossType,
        bossNames[bossType] or "Boss",
        prefabMap[bossType] or "Ogre",
        1,
        armorValues[bossType] or 0,
        nil
    )

    boss.ability = bossType

    if self.spawnModels ~= false then
        spawnModel(boss)
    end

    if bossType == "location" then
        AutoBattleSystem = AutoBattleSystem or require(parent:WaitForChild("AutoBattleSystem"))
        if AutoBattleSystem and AutoBattleSystem.disableForDuration then
            AutoBattleSystem:disableForDuration(5)
        end
    end

    table.insert(self.enemies, boss)
    NetworkSystem:fireAllClients("EnemySpawn", boss.name, boss.position, bossType)
    EventManager:Get("SpawnBoss"):Fire(bossType)
end

---Updates enemy movement by computing a path toward the player and moving a
--  small step along it. In the test environment this uses a minimal
--  PathfindingService stub to return a straight line path.
-- @param dt number delta time since the last update
function EnemySystem:update(dt)
    AutoBattleSystem = AutoBattleSystem or require(parent:WaitForChild("AutoBattleSystem"))
    PlayerSystem = PlayerSystem or require(parent:WaitForChild("PlayerSystem"))
    local playerPos = AutoBattleSystem.playerPosition
    if not playerPos then
        return
    end
    local pathService = getPathfindingService()
    for _, enemy in ipairs(self.enemies) do
        enemy.attackTimer = (enemy.attackTimer or 0) - dt
        if enemy.ability == "mini" and not enemy.arenaShifted then
            enemy.arenaShifted = true
            self.moveSpeed = self.moveSpeed * 1.2
        elseif enemy.ability == "boss" and not enemy.cloned and enemy.health <= enemy.maxHealth/2 then
            enemy.cloned = true
            local clone = createEnemy(enemy.maxHealth/2, enemy.damage/2, {x=enemy.position.x+2,y=enemy.position.y,z=enemy.position.z}, nil, enemy.name .. " Clone", enemy.prefab, enemy.level, 0)
            if self.spawnModels ~= false then spawnModel(clone) end
            table.insert(self.enemies, clone)
            NetworkSystem:fireAllClients("EnemySpawn", clone.name, clone.position, nil)
        end
        local model = enemy.model
        local primaryPart = model and (model.PrimaryPart or model.primaryPart)
        if primaryPart then
            local sx, sy, sz = getCoords(primaryPart.Position or primaryPart.position)
            local startPos = createVector3(sx, sy, sz)
            local goal = createVector3(playerPos.x, playerPos.y, 0)
            local path = pathService:CreatePath()
            path:ComputeAsync(startPos, goal)
            enemy.path = path:GetWaypoints()
            if #enemy.path >= 2 then
                local nextPos = enemy.path[2]
                local nx, ny, nz = getCoords(nextPos.Position or nextPos)
                local dx, dy, dz = nx - sx, ny - sy, nz - sz
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist > 0 then
                    local speed = self.moveSpeed
                    if enemy.behavior == "fast" then
                        speed = speed * 1.5
                    end
                    local step = math.min(speed * dt, dist)
                    local tx, ty, tz = sx + dx / dist * step, sy + dy / dist * step, sz + dz / dist * step
                    enemy.position.x, enemy.position.y, enemy.position.z = tx, ty, tz
                    if primaryPart.Position ~= nil then
                        primaryPart.Position = createVector3(tx, ty, tz)
                    else
                        primaryPart.position = {x = tx, y = ty, z = tz}
                    end
                end
                local pdx, pdy = enemy.position.x - playerPos.x, enemy.position.y - playerPos.y
                local pdist = math.sqrt(pdx * pdx + pdy * pdy)
                if enemy.behavior == "shoot" or enemy.behavior == "ranged" then
                    local range = enemy.behavior == "ranged" and 15 or 10
                    if pdist <= range and enemy.attackTimer <= 0 then
                        PlayerSystem:takeDamage(enemy.damage or 0)
                        enemy.attackTimer = enemy.attackCooldown or self.attackCooldown
                    end
                elseif pdist <= self.attackRange and enemy.attackTimer <= 0 then
                    PlayerSystem:takeDamage(enemy.damage or 0)
                    enemy.attackTimer = enemy.attackCooldown or self.attackCooldown
                end
            end
        end
        if enemy.behavior == "jump" then
            enemy.jumpTimer = (enemy.jumpTimer or 0) - dt
            if enemy.jumpTimer <= 0 then
                enemy.jumpTimer = 2
                enemy.position.y = enemy.position.y + 3
                if primaryPart then
                    if primaryPart.Position ~= nil then
                        primaryPart.Position = createVector3(enemy.position.x, enemy.position.y, enemy.position.z)
                    else
                        primaryPart.position = {x = enemy.position.x, y = enemy.position.y, z = enemy.position.z}
                    end
                end
            end
        end
        NetworkSystem:fireAllClients("EnemyUpdate", enemy.name, enemy.position, enemy.health, enemy.armor)
    end
end

return EnemySystem
