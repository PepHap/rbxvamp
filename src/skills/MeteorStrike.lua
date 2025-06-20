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
local MeteorStrike = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Calls down a fiery meteor at the target position
function MeteorStrike.cast(caster, skill, target)
    if MeteorStrike.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "MeteorStrike"
        part.Shape = Enum.PartType.Ball
        part.BrickColor = BrickColor.new("Bright orange")
        part.Size = Vector3.new(2,2,2)
        part.CanCollide = false
        part.Anchored = true
        local pos = target and target.Position or (caster and caster.Position)
        if pos then
            part.CFrame = CFrame.new(pos + Vector3.new(0, 20, 0))
        else
            part.CFrame = CFrame.new(0, 20, 0)
        end
        part.Parent = ws
        local tweenService = game:GetService("TweenService")
        local goal = {CFrame = part.CFrame - Vector3.new(0, 20, 0)}
        local tween = tweenService:Create(part, TweenInfo.new(0.5), goal)
        tween:Play()
        tween.Completed:Connect(function()
            part:Destroy()
        end)
    else
        MeteorStrike.lastCast = {target = target}
    end
end

-- Increase radius as it levels up
function MeteorStrike.applyLevel(skill)
    if skill.level >= 5 then
        skill.radius = (skill.radius or 0) + 2
    end
end

return MeteorStrike
