local EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
local Lightning = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
}

-- Spawns a blue projectile at the caster or target
function Lightning.cast(caster, skill, target)
    if Lightning.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "Lightning"
        part.BrickColor = BrickColor.new("Bright blue")
        part.CanCollide = false
        part.Anchored = true
        if target and target.CFrame then
            part.CFrame = target.CFrame
        elseif caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 0.5) end
    else
        Lightning.lastCast = {target = target}
    end
end

-- Increase damage when leveled
function Lightning.applyLevel(skill)
    if skill.level >= 5 then
        skill.damage = (skill.damage or 0) + 5
    end
end

return Lightning
