local ModuleUtil = {}

---Safely requires a child ModuleScript with optional waiting and error handling.
-- @param parent Instance parent container
-- @param name string child name to require
-- @param timeout number? maximum time to wait for the child
-- @return any loaded module or nil
function ModuleUtil.requireChild(parent, name, timeout)
    local containers = {parent, parent.Parent}
    local child
    local function search(container)
        local found = container and container:FindFirstChild(name)
        if not found and container then
            -- Rojo-style layouts may name modules like "Module.client.module".
            -- Additionally some build setups place sibling modules like
            -- "Module.client" under the same parent rather than as a child.
            local altNames = {
                container.Name .. "." .. name .. ".module",
                container.Name .. "." .. name .. ".module.lua",
                container.Name .. "." .. name .. ".client.module",
                container.Name .. "." .. name .. ".client.module.lua",
                container.Name .. "." .. name .. ".server.module",
                container.Name .. "." .. name .. ".server.module.lua",
                container.Name .. "_" .. name,
                container.Name .. "_" .. name .. ".module",
                container.Name .. "_" .. name .. ".module.lua",
                name .. ".module",
                name .. ".module.lua",
                name .. ".client.module",
                name .. ".client.module.lua",
                name .. ".server.module",
                name .. ".server.module.lua",
                container.Name .. "." .. name,
                parent.Name .. "." .. name .. ".module",
                parent.Name .. "." .. name .. ".module.lua",
                parent.Name .. "." .. name .. ".client.module",
                parent.Name .. "." .. name .. ".client.module.lua",
                parent.Name .. "." .. name .. ".server.module",
                parent.Name .. "." .. name .. ".server.module.lua",
                parent.Name .. "_" .. name,
                parent.Name .. "_" .. name .. ".module",
                parent.Name .. "_" .. name .. ".module.lua",
                parent.Name .. "." .. name,
            }
            for _, n in ipairs(altNames) do
                found = container:FindFirstChild(n)
                if found then break end
            end
        end
        -- Fall back to searching the container's parent for a sibling named
        -- like "Module.client" when still not located.
        if not found and container and container ~= container.Parent then
            local siblingNames = {
                parent.Name .. "." .. name,
                parent.Name .. "." .. name .. ".module",
                parent.Name .. "." .. name .. ".module.lua",
                parent.Name .. "." .. name .. ".client.module",
                parent.Name .. "." .. name .. ".client.module.lua",
                parent.Name .. "." .. name .. ".server.module",
                parent.Name .. "." .. name .. ".server.module.lua",
                parent.Name .. "_" .. name,
                parent.Name .. "_" .. name .. ".module",
                parent.Name .. "_" .. name .. ".module.lua",
            }
            for _, n in ipairs(siblingNames) do
                found = container.Parent and container.Parent:FindFirstChild(n)
                if found then break end
            end
        end
        return found
    end

    for _, c in ipairs(containers) do
        child = search(c)
        if child then break end
    end

    if not child then
        timeout = timeout or 5
        local elapsed = 0
        while elapsed < timeout and not child do
            for _, c in ipairs(containers) do
                if c then
                    child = search(c)
                    if child then break end
                end
            end
            if child then break end
            elapsed = elapsed + task.wait(0.05)
        end
    end

    if not child then
        warn(("Missing module %s under %s"):format(name, parent:GetFullName()))
        return nil
    end
    if not child:IsA("ModuleScript") then
        warn(("Child %s under %s is not a ModuleScript (found %s)")
            :format(child.Name, parent:GetFullName(), child.ClassName))
        return nil
    end
    local ok, mod = pcall(require, child)
    if not ok then
        warn(("Error requiring %s: %s"):format(child:GetFullName(), mod))
        return nil
    end
    if mod == nil then
        warn(("Module %s returned nil"):format(child:GetFullName()))
        return nil
    end
    return mod
end

---Loads a module from the ReplicatedStorage assets folder.
-- Falls back to returning nil when the module cannot be found.
-- @param name string module name within ReplicatedStorage.assets
-- @param timeout number? time to wait for the module
-- @return any loaded module or nil
function ModuleUtil.loadAssetModule(name, timeout)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local assets = ReplicatedStorage:FindFirstChild("assets")
    if not assets then
        assets = ServerStorage:FindFirstChild("assets")
    end

    if assets then
        local mod = ModuleUtil.requireChild(assets, name, timeout or 5)
        if mod then
            return mod
        end
    end

    -- Fallback to a local assets folder so tests can run outside Studio
    local localAssets = script.Parent.Parent:FindFirstChild("assets")
    if localAssets then
        local child = localAssets:FindFirstChild(name)
        if child and child:IsA("ModuleScript") then
            local ok, result = pcall(require, child)
            if ok then
                return result
            end
        end
    end

    warn(("Missing assets folder or module %s"):format(name))
    return nil
end

return ModuleUtil
