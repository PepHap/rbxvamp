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
local FrostNova = {
    useRobloxObjects = EnvironmentUtil.detectRoblox(),
}

-- Creates an icy blast around the caster damaging nearby foes
function FrostNova.cast(caster, skill, target)
    if FrostNova.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "FrostNova"
        part.Shape = Enum.PartType.Ball
        part.BrickColor = BrickColor.new("Baby blue")
        part.Transparency = 0.5
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(skill.radius or 5, skill.radius or 5, skill.radius or 5)
        if caster and caster.PrimaryPart then
            part.CFrame = caster.PrimaryPart.CFrame
        end
        part.Parent = ws
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(part, 1) end
    else
        FrostNova.lastCast = {radius = skill.radius, damage = skill.damage}
    end
end

-- Adds radius and damage bonuses as the skill levels up
function FrostNova.applyLevel(skill)
    if skill.level >= 5 then
        skill.radius = (skill.radius or 0) + 1
    end
    if skill.level >= 10 then
        skill.damage = (skill.damage or 0) + 5
    end
end

return FrostNova
