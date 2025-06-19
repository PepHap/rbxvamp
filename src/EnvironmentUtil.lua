local EnvironmentUtil = {}

function EnvironmentUtil.detectRoblox()
    return typeof ~= nil and Instance ~= nil and type(Instance.new) == "function"
end

return EnvironmentUtil
