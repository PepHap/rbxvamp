-- spec_helper.lua
-- Provides Roblox-like globals for the test environment
local replicated = {
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
        end
    end
}

local playerGui = {children = {}}
function playerGui:GetChildren()
    return self.children
end

local players = {
    LocalPlayer = {
        WaitForChild = function(_, child)
            if child == "PlayerGui" then
                return playerGui
            end
        end
    }
}

local UIS = {
    InputBegan = {
        Connect = function(_, fn)
            UIS._callback = fn
        end
    }
}

_G.game = _G.game or {
    GetService = function(_, name)
        if name == "ReplicatedStorage" then
            return replicated
        elseif name == "Players" then
            return players
        elseif name == "UserInputService" then
            return UIS
        end
        return nil
    end
}

_G.Instance = _G.Instance or {
    new = function(class)
        local obj = {ClassName = class, children = {}}
        function obj:GetChildren()
            return self.children
        end
        function obj:IsA(name)
            return self.ClassName == name
        end
        function obj:Destroy()
            obj.destroyed = true
        end
        return setmetatable(obj, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                if k == "Parent" and type(v) == "table" then
                    v.children = v.children or {}
                    table.insert(v.children, t)
                end
            end
        })
    end
}

_G.script = _G.script or {
    Parent = {
        WaitForChild = function(_, name)
            return "src." .. name
        end
    }
}

_G.Color3 = _G.Color3 or {
    fromRGB = function(r, g, b) return {r=r, g=g, b=b} end,
    new = function(r, g, b) return {r=r, g=g, b=b} end
}

_G.UDim2 = _G.UDim2 or {
    fromScale = function(x, y) return {ScaleX=x, ScaleY=y} end,
    new = function(a, b, c, d) return {a=a, b=b, c=c, d=d} end
}

_G.UDim = _G.UDim or {
    new = function(a, b) return {Scale=a, Offset=b} end
}

_G.Enum = _G.Enum or {
    FillDirection = {Vertical = "Vertical"},
    SortOrder = {LayoutOrder = "LayoutOrder"},
    Font = {Gotham = "Gotham"},
    KeyCode = {B = "B"}
}
