local EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
local IceShard = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
}

-- Spawns a cyan shard moving forward
function IceShard.cast(caster, skill, target)
    if IceShard.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "IceShard"
        part.BrickColor = BrickColor.new("Cyan")
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
        if debris then debris:AddItem(part, 2) end
    else
        IceShard.lastCast = {target = target}
    end
end

-- Increases radius when leveled
function IceShard.applyLevel(skill)
    if skill.level >= 5 then
        skill.radius = (skill.radius or 0) + 1
    end
end

return IceShard
