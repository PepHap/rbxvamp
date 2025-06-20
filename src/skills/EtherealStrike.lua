local EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
local EtherealStrike = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
}

-- Creates a short range blade slash effect
function EtherealStrike.cast(caster, skill, target)
    if EtherealStrike.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "EtherealSlash"
        part.Size = Vector3.new(3, 3, 1)
        part.Transparency = 0.5
        part.CanCollide = false
        part.Anchored = true
        if caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 0.5) end
    else
        EtherealStrike.lastCast = {level = skill.level, target = target}
    end
end

-- Reduces cooldown and increases damage as levels rise
function EtherealStrike.applyLevel(skill)
    if skill.level >= 3 then
        skill.cooldown = math.max(2, (skill.cooldown or 6) - 1)
    end
    if skill.level >= 5 then
        skill.damage = (skill.damage or 50) + 10
    end
end

return EtherealStrike
