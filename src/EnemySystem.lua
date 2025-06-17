-- EnemySystem.lua
-- Spawns waves of enemies and bosses.

local EnemySystem = {}
local EventManager = require(script.Parent:WaitForChild("EventManager"))

-- Resolve other module paths relative to how this module was required so that
-- tests using relative paths function correctly.
-- Parent folder reference for requiring sibling modules when running
-- inside Roblox Studio.
local parent = script.Parent

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
EnemySystem.useRobloxObjects = false

---Movement speed in studs per second used when advancing along a path.
EnemySystem.moveSpeed = 1

---Distance within which enemies can damage the player.
EnemySystem.attackRange = 2

---Delay between successive enemy attacks in seconds.
EnemySystem.attackCooldown = 1

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


---Utility to create a basic enemy table. The returned table describes the
--  enemy's health, damage, current position and optional type string.
--  @param health number
--  @param damage number
--  @param position table table containing x/y/z coordinates
--  @param enemyType string|nil classification such as "mini" or "boss"
--  @param name string display name for this enemy
--  @return table new enemy object
local function createEnemy(health, damage, position, enemyType, name, prefab)
    return {
        health = health,
        damage = damage,
        position = position,
        type = enemyType,
        name = name,
        prefab = prefab,
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
                textLabel.Text = enemy.name
                textLabel.Parent = billboardGui
                billboardGui.Parent = model
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
        textLabel = {text = enemy.name}
    }
    enemy.model = model
    return model
end

---List of currently active enemies in the world.
EnemySystem.enemies = {}

---Last level used when spawning a wave.
EnemySystem.lastWaveLevel = nil

---Last boss type that was spawned.
EnemySystem.lastBossType = nil

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
    local healthPerLevel = 2
    local baseDamage = 1
    local damagePerLevel = 1

    local hScale = self.healthScale or 1
    local dScale = self.damageScale or 1

    for i = 1, count do
        local enemy = createEnemy(
            (baseHealth + healthPerLevel * level) * hScale,
            (baseDamage + damagePerLevel * level) * dScale,
            {x = i, y = 0, z = 0},
            nil,
            string.format("Enemy %d", i),
            "Goblin"
        )
        if self.spawnModels ~= false then
            spawnModel(enemy)
        end
        table.insert(self.enemies, enemy)
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

    local hScale = self.healthScale or 1
    local dScale = self.damageScale or 1

    local bossNames = {
        mini = "Mini Boss",
        boss = "Boss",
        location = "Location Boss"
    }
    local prefabMap = {mini = "Ogre", boss = "Dragon", location = "Dragon"}
    local boss = createEnemy(
        (bossHealth[bossType] or 20) * hScale,
        (bossDamage[bossType] or 2) * dScale,
        {x = 0, y = 0, z = 0},
        bossType,
        bossNames[bossType] or "Boss",
        prefabMap[bossType] or "Ogre"
    )

    if self.spawnModels ~= false then
        spawnModel(boss)
    end

    table.insert(self.enemies, boss)
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
                    local step = math.min(self.moveSpeed * dt, dist)
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
                if pdist <= self.attackRange and enemy.attackTimer <= 0 then
                    PlayerSystem:takeDamage(enemy.damage or 0)
                    enemy.attackTimer = enemy.attackCooldown or self.attackCooldown
                end
            end
        end
    end
end

return EnemySystem
