local EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
local ShadowFlame = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Launches a purple flame that slowly travels forward and burns enemies
function ShadowFlame.cast(caster, skill, target)
    if ShadowFlame.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "ShadowFlame"
        part.BrickColor = BrickColor.new("Royal purple")
        part.CanCollide = false
        part.Anchored = true
        if caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (caster and caster.CFrame.LookVector or Vector3.new(0,0,-1)) * 40
        bv.Parent = part
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 3) end
    else
        ShadowFlame.lastCast = {level = skill.level, target = target}
    end
end

-- At level 5 the flame size and damage increase
function ShadowFlame.applyLevel(skill)
    if skill.level >= 5 then
        skill.damage = (skill.damage or 20) + 10
        skill.radius = (skill.radius or 4) + 1
    end
end

return ShadowFlame
