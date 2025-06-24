local ModuleUtil = {}

---Safely requires a child ModuleScript with optional waiting and error handling.
-- @param parent Instance parent container
-- @param name string child name to require
-- @param timeout number? maximum time to wait for the child
-- @return any loaded module or nil
function ModuleUtil.requireChild(parent, name, timeout)
    local child = parent:FindFirstChild(name)
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
