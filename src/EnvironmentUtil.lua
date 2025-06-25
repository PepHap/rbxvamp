local EnvironmentUtil = {}

-- Determines whether the current environment is Roblox based on common globals.
-- https://create.roblox.com/docs/reference/engine/libraries/Instance
function EnvironmentUtil.detectRoblox()
    return typeof ~= nil
        and Instance ~= nil and type(Instance.new) == "function"
        and game ~= nil and type(game.GetService) == "function"
end

return EnvironmentUtil
