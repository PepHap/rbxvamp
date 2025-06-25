local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))

local BlurManager = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
    effect = nil,
    refCount = 0,
}

local function createEffect()
    if not BlurManager.useRobloxObjects then
        BlurManager.effect = BlurManager.effect or {}
        return
    end
    if BlurManager.effect and BlurManager.effect.Parent then
        return
    end
    local ok, lighting = pcall(function()
        return game:GetService("Lighting")
    end)
    if not ok or not lighting then
        return
    end
    local success, eff = pcall(function()
        return Instance.new("BlurEffect")
    end)
    if success and eff then
        eff.Size = 10
        eff.Parent = lighting
        BlurManager.effect = eff
    end
end

function BlurManager:add()
    self.refCount = (self.refCount or 0) + 1
    createEffect()
    if self.effect then
        local ok = pcall(function()
            self.effect.Size = 10
        end)
        if not ok and type(self.effect) == "table" then
            self.effect.Size = 10
        end
    end
end

function BlurManager:remove()
    if (self.refCount or 0) <= 0 then return end
    self.refCount = self.refCount - 1
    if self.refCount == 0 and self.effect then
        local ok = pcall(function()
            -- Fade out before destroying to avoid a visible jump
            self.effect.Size = 0
            if self.effect.Destroy then
                self.effect:Destroy()
            end
        end)
        if not ok and type(self.effect) == "table" then
            self.effect = nil
        end
        self.effect = nil
    end
end

---Returns true when a blur effect is currently active.
function BlurManager:isActive()
    return self.refCount > 0
end

---Forcibly clears the blur effect and resets the reference count.
function BlurManager:reset()
    self.refCount = 0
    if self.effect then
        local ok = pcall(function()
            self.effect.Size = 0
            if self.effect.Destroy then
                self.effect:Destroy()
            end
        end)
        if not ok and type(self.effect) == "table" then
            self.effect = nil
        end
        self.effect = nil
    end
end

return BlurManager
