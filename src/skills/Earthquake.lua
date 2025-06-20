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
local Earthquake = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Creates a quick ground shockwave around the caster
function Earthquake.cast(caster, skill, target)
    if Earthquake.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "Earthquake"
        part.Anchored = true
        part.CanCollide = false
        part.BrickColor = BrickColor.new("Reddish brown")
        part.Size = Vector3.new(1,0.2,1)
        if caster and caster.Position then
            part.CFrame = CFrame.new(caster.Position)
        end
        part.Parent = ws
        local tweenService = game:GetService("TweenService")
        local goal = {Size = Vector3.new((skill.radius or 4)*2, 0.2, (skill.radius or 4)*2)}
        local tween = tweenService:Create(part, TweenInfo.new(0.4), goal)
        tween:Play()
        tween.Completed:Connect(function()
            part:Destroy()
        end)
    else
        Earthquake.lastCast = {radius = skill.radius}
    end
end

-- Higher levels reduce cooldown slightly
function Earthquake.applyLevel(skill)
    if skill.level >= 5 then
        skill.cooldown = math.max(1, (skill.cooldown or 0) - 1)
    end
end

return Earthquake
