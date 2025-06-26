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
                name .. ".module",
                name .. ".module.lua",
                container.Name .. "." .. name,
                parent.Name .. "." .. name .. ".module",
                parent.Name .. "." .. name .. ".module.lua",
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
        for _, c in ipairs(containers) do
            if c then
                local ok, result = pcall(c.WaitForChild, c, name, timeout)
                if ok then
                    child = result
                    break
                end
            end
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
    local assets = ReplicatedStorage:FindFirstChild("assets")
    if not assets then
        warn("Missing assets folder in ReplicatedStorage")
        return nil
    end
    return ModuleUtil.requireChild(assets, name, timeout or 5)
end

return ModuleUtil
