-- spec_helper.lua
-- Provides Roblox-like globals for the test environment
_G.game = _G.game or {
    GetService = function(_, name)
        if name == "ReplicatedStorage" then
            return {
                WaitForChild = function(_, child)
                    if child == "assets" then
                        return {
                            WaitForChild = function(_, sub)
                                return "assets." .. sub
                            end
                        }
                    end
                end
            }
        end
        return nil
    end
}

_G.Instance = _G.Instance or { new = function(class) return {ClassName = class} end }

_G.script = _G.script or {
    Parent = {
        WaitForChild = function(_, name)
            return "src." .. name
        end
    }
}
