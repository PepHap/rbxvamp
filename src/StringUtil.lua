local StringUtil = {}

-- Safely converts various name representations to plain strings.
function StringUtil.toNameString(name)
    if type(name) == "table" then
        return name.name or name.text or name.displayName or "[table]"
    end
    return tostring(name or "")
end

return StringUtil
