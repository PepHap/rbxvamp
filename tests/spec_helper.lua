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
                    elseif child == "src" then
                        return {
                            WaitForChild = function(_, sub)
                                return "src." .. sub
                            end
                        }
                    elseif child == "server" then
                        return {
                            WaitForChild = function(_, sub)
                                return "server.systems." .. sub
                            end
                        }
                    end
                end
            }
        elseif name == "RunService" then
            return {
                IsClient = function() return true end
            }
        end
        return nil
    end
}

_G.Instance = _G.Instance or { new = function(class) return {ClassName = class} end }

_G.script = _G.script or {
    Parent = {
        WaitForChild = function(_, name)
            if name == "server" then
                return {
                    WaitForChild = function(_, sub)
                        return "server.systems." .. sub
                    end
                }
            else
                return "src." .. name
            end
        end,
        FindFirstChild = function(_, name)
            return "src." .. name
        end
    }
}

_G.UDim2 = _G.UDim2 or {
    new = function(a, b, c, d)
        return {ScaleX = a, OffsetX = b, ScaleY = c, OffsetY = d}
    end
}

_G.Color3 = _G.Color3 or {
    fromRGB = function(r, g, b)
        return {r=r,g=g,b=b}
    end,
    new = function(r, g, b)
        return {r=r,g=g,b=b}
    end
}

_G.Enum = _G.Enum or {
    FillDirection = {Horizontal="Horizontal"},
    SortOrder = {LayoutOrder="LayoutOrder"}
}
