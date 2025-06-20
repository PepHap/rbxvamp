local function detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

local EnemyUISystem = {
    useRobloxObjects = detectRoblox(),
    enemies = {}
}

local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

local function createModel(name, pos)
    if EnemyUISystem.useRobloxObjects then
        local part = Instance.new("Part")
        part.Anchored = true
        part.Size = Vector3.new(1,1,1)
        part.Name = name
        part.Position = Vector3.new(pos.x or 0, pos.y or 0, pos.z or 0)
        part.Parent = workspace
        return part
    end
    return {name = name, position = {x = pos.x, y = pos.y, z = pos.z}}
end

function EnemyUISystem:start()
    NetworkSystem:onClientEvent("EnemySpawn", function(name, pos)
        local model = createModel(name, pos)
        EnemyUISystem.enemies[name] = {model = model, position = pos}
    end)

    NetworkSystem:onClientEvent("EnemyUpdate", function(name, pos)
        local e = EnemyUISystem.enemies[name]
        if e then
            e.position = pos
            local m = e.model
            if m then
                if m.Position then
                    m.Position = Vector3.new(pos.x or 0, pos.y or 0, pos.z or 0)
                elseif m.position then
                    m.position = {x = pos.x, y = pos.y, z = pos.z}
                end
            end
        end
    end)

    NetworkSystem:onClientEvent("EnemyRemove", function(name)
        local e = EnemyUISystem.enemies[name]
        if e then
            if e.model and e.model.Destroy then
                e.model:Destroy()
            end
            EnemyUISystem.enemies[name] = nil
        end
    end)
end

return EnemyUISystem

