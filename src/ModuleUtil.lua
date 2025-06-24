local ModuleUtil = {}

---Safely requires a child ModuleScript if present without waiting indefinitely.
--@param parent Instance parent container
--@param name string child name to require
--@return any loaded module or nil
function ModuleUtil.requireChild(parent, name)
    local child = parent:FindFirstChild(name)
    if not child then
        warn(("Missing module %s under %s"):format(name, parent:GetFullName()))
        return nil
    end
    return require(child)
end

return ModuleUtil
