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
local ArcaneBurst = { useRobloxObjects = EnvironmentUtil.detectRoblox() }

-- Emits a purple expanding sphere around the caster
function ArcaneBurst.cast(caster, skill, target)
    if ArcaneBurst.useRobloxObjects and game and typeof and typeof(Instance.new) == "function" then
        local ws = game:GetService("Workspace")
        if not ws then return end
        local part = Instance.new("Part")
        part.Name = "ArcaneBurst"
        part.Shape = Enum.PartType.Ball
        part.BrickColor = BrickColor.new("Royal purple")
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(1,1,1)
        if caster and caster.CFrame then
            part.CFrame = caster.CFrame
        end
        part.Parent = ws
        local tweenService = game:GetService("TweenService")
        local goal = {Size = Vector3.new((skill.radius or 4)*2,(skill.radius or 4)*2,(skill.radius or 4)*2)}
        local tween = tweenService:Create(part, TweenInfo.new(0.5), goal)
        tween:Play()
        tween.Completed:Connect(function()
            part:Destroy()
        end)
    else
        ArcaneBurst.lastCast = {radius = skill.radius}
    end
end

-- Reduce cooldown at higher levels
function ArcaneBurst.applyLevel(skill)
    if skill.level >= 5 then
        skill.cooldown = math.max(2, (skill.cooldown or 0) - 2)
    end
end

return ArcaneBurst
