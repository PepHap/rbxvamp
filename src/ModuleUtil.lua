local ModuleUtil = {}

---Safely requires a child ModuleScript with optional waiting and error handling.
-- @param parent Instance parent container
-- @param name string child name to require
-- @param timeout number? maximum time to wait for the child
-- @return any loaded module or nil
function ModuleUtil.requireChild(parent, name, timeout)
    local child = parent:FindFirstChild(name)
    if not child then
        -- Rojo-style layouts may name modules like "Module.client.module". When
        -- running the source directly in Studio those children might not be
        -- created, so attempt to locate them by alternative names.
        local altNames = {
            parent.Name .. "." .. name .. ".module",
            parent.Name .. "." .. name .. ".module.lua",
            name .. ".module",
            name .. ".module.lua",
            parent.Name .. "." .. name,
        }
        for _, n in ipairs(altNames) do
            child = parent:FindFirstChild(n)
            if child then break end
        end
    end
    if not child then
        timeout = timeout or 5
        local ok, result = pcall(parent.WaitForChild, parent, name, timeout)
        if ok then
            child = result
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

return ModuleUtil
