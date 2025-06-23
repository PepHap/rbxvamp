local LocalizationUtil = {}
local EnvironmentUtil = require(script.Parent:WaitForChild("EnvironmentUtil"))
local useRoblox = EnvironmentUtil.detectRoblox()
local service
local current = "en"
if useRoblox then
    local ok, srv = pcall(function()
        return game:GetService("LocalizationService")
    end)
    if ok then
        service = srv
        current = service.RobloxLocaleId
    end
end

local texts = {
    floor = {en="Floor", ru="Этаж"},
    enemiesLeft = {en="Enemies left", ru="Осталось врагов"},
    nextReward = {en="Next reward", ru="Награда"},
}

function LocalizationUtil.setLocale(locale)
    current = locale or current
end

function LocalizationUtil.translate(key)
    local entry = texts[key]
    if type(entry) == "table" then
        return entry[current] or entry.en or key
    end
    return entry or key
end

return LocalizationUtil
