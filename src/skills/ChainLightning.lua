local EnvironmentUtil

pcall(function()
    EnvironmentUtil = require(script.Parent.Parent:WaitForChild("EnvironmentUtil"))
end)
EnvironmentUtil = EnvironmentUtil or require("src.EnvironmentUtil")

local ChainLightning = { useRobloxObjects = EnvironmentUtil.detectRoblox(), }


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
local ChainLightning = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Creates a yellow strike effect that jumps between targets
function ChainLightning.cast(caster, skill, target)
    if ChainLightning.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local startPos = caster and caster.CFrame.Position or Vector3.new()
        local endPos = target and target.CFrame.Position or startPos + Vector3.new(0,0,-5)
        local beam = Instance.new("Part")
        beam.Name = "ChainLightning"
        beam.Anchored = true
        beam.CanCollide = false
        beam.BrickColor = BrickColor.new("Electric blue")
        beam.Size = Vector3.new(0.2,0.2,(startPos - endPos).Magnitude)
        beam.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-beam.Size.Z/2)
        beam.Parent = ws
        local debris = game:GetService("Debris")
        if debris then debris:AddItem(beam, 0.3) end
    else
        ChainLightning.lastCast = {target = target}
    end
end

function ChainLightning.applyLevel(skill)
    if skill.level >= 3 then
        skill.damage = (skill.damage or 0) + 3
    end
    if skill.level >= 6 then
        skill.chainTargets = (skill.chainTargets or 1) + 1
        local part = Instance.new("Part")
        part.Name = "ChainLightning"
        part.BrickColor = BrickColor.new("New Yeller")
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
        ChainLightning.lastCast = {level = skill.level, target = target}
    end
end

return ChainLightning
