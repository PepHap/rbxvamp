local EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
local Fireball = {
    -- Set to true when running inside Roblox to use actual objects
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
}

-- Spawns a red projectile moving forward from the caster
function Fireball.cast(caster, skill, target)
    if Fireball.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "Fireball"
        part.BrickColor = BrickColor.new("Bright red")
        part.CanCollide = false
        part.Anchored = true
        if caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (caster and caster.CFrame.LookVector or Vector3.new(0,0,-1)) * 50
        bv.Parent = part
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 2) end
    else
        -- Fallback for non-Roblox environments used in tests
        Fireball.lastCast = {level = skill.level, target = target}
    end
end

-- Applies level-based bonuses to the skill table
function Fireball.applyLevel(skill)
    if skill.level >= 5 then
        skill.cooldown = math.max(1, (skill.cooldown or 0) - 1)
    end
    if skill.level >= 10 then
        skill.extraProjectiles = 1
    end
end

return Fireball

