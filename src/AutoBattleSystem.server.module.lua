local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("AutoBattleSystem server module should only be required on the server", 2)
end

local serverFolder = script.Parent.Parent.Parent:FindFirstChild("server")
local systems = serverFolder and serverFolder:FindFirstChild("systems")
if systems then
    return require(systems:WaitForChild("AutoBattleSystem"))
end
return {}
