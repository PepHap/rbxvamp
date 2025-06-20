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
local WindSlash = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Creates a quick green slash effect in front of the caster
function WindSlash.cast(caster, skill, target)
    if WindSlash.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "WindSlash"
        part.BrickColor = BrickColor.new("Bright green")
        part.CanCollide = false
        part.Anchored = true
        if caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (caster and caster.CFrame.LookVector or Vector3.new(0,0,-1)) * 60
        bv.Parent = part
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 1) end
    else
        WindSlash.lastCast = {target = target}
    end
end

-- Adds a second slash when leveled up
function WindSlash.applyLevel(skill)
    if skill.level >= 5 then
        skill.extraSlashes = 1
    end
end

return WindSlash
