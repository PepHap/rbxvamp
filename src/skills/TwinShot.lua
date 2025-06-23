local EnvironmentUtil
do
    local ok, mod = pcall(function()
        return script.Parent.Parent:WaitForChild("EnvironmentUtil")
    end)
    if ok and mod then
        EnvironmentUtil = require(mod)
    else
        EnvironmentUtil = require("src.EnvironmentUtil")
    end
end

local TwinShot = {useRobloxObjects = EnvironmentUtil.detectRoblox()}

--[[
    Fires two quick projectiles forward from the caster. At higher levels the
    cooldown decreases slightly allowing more frequent use.
    https://create.roblox.com/docs/reference/engine/classes/Part
]]
function TwinShot.cast(caster, skill, target)
    if TwinShot.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws or not caster or not caster.CFrame then return end
        for i = 1, 2 do
            local bolt = Instance.new("Part")
            bolt.Name = "TwinShotBolt"
            bolt.BrickColor = BrickColor.new("Bright yellow")
            bolt.CanCollide = false
            bolt.Anchored = true
            bolt.CFrame = caster.CFrame * CFrame.new(0, 0, -i)
            bolt.Parent = ws
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = caster.CFrame.LookVector * 80
            bv.Parent = bolt
            local debris = game:GetService("Debris")
            if debris then debris:AddItem(bolt, 1) end
        end
    else
        TwinShot.lastCast = {level = skill.level, target = target}
    end
end

function TwinShot.applyLevel(skill)
    if skill.level >= 5 then
        skill.cooldown = math.max(1, (skill.cooldown or 0) - 0.5)
    end
end

return TwinShot
