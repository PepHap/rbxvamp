local LocalizationSystem = {
    translations = {}
}

local LocalizationService
local success, service = pcall(function()
    return game:GetService("LocalizationService")
end)
if success then
    LocalizationService = service
end

-- Default English terms
LocalizationSystem.translations.en = {
    ["Floor"] = "Floor",
    ["kills to"] = "kills to",
    ["Boss"] = "Boss",
    ["Mini Boss"] = "Mini Boss",
    ["Area Boss"] = "Area Boss",
    ["Location"] = "Location",
    ["Ether"] = "Ether",
    ["Crystals"] = "Crystals",
    ["Gauge"] = "Gauge",
    ["Level"] = "Level",
    ["Frozen Wasteland"] = "Frozen Wasteland",
    ["Meadow"] = "Meadow",
    ["Dungeon"] = "Dungeon",
    ["Ruins"] = "Ruins",
    ["Volcano"] = "Volcano",
    ["Sky Castle"] = "Sky Castle",
    ["Abyss"] = "Abyss",
    ["Underworld"] = "Underworld",
    ["Next Reward"] = "Next Reward",
    ["Next Milestone"] = "Next Milestone",
    ["XP"] = "XP",
    ["Haunted Manor"] = "Haunted Manor",

}

-- Russian translations covering common UI labels
LocalizationSystem.translations.ru = {
    ["Floor"] = "Этаж",
    ["kills to"] = "убить до",
    ["Boss"] = "Босс",
    ["Mini Boss"] = "Мини-босс",
    ["Area Boss"] = "Босс локации",
    ["Location"] = "Локация",
    ["Ether"] = "Эфир",
    ["Crystals"] = "Кристаллы",
    ["Gauge"] = "Шкала",
    ["Level"] = "Уровень",
    ["Frozen Wasteland"] = "Замерзшие пустоши",
    ["Meadow"] = "Луг",
    ["Dungeon"] = "Подземелье",
    ["Ruins"] = "Руины",
    ["Volcano"] = "Вулкан",
    ["Sky Castle"] = "Небесный замок",
    ["Abyss"] = "Бездна",
    ["Underworld"] = "Преисподняя",
    ["Next Reward"] = "Следующая награда",
    ["Next Milestone"] = "Следующая цель",
    ["XP"] = "Опыта",
    ["Haunted Manor"] = "Проклятое поместье",
}

---Returns a localized string for the given key or the key itself.
function LocalizationSystem:get(key)
    local lang = "en"
    if LocalizationService and LocalizationService.RobloxLocaleId then
        lang = LocalizationService.RobloxLocaleId:sub(1, 2)
    end
    local tbl = self.translations[lang] or self.translations.en
    if tbl and tbl[key] then
        return tbl[key]
    end
    return key
end

---Adds translation entries for the specified language.
function LocalizationSystem:addLanguage(lang, entries)
    if type(lang) == "string" and type(entries) == "table" then
        self.translations[lang] = entries
    end
end

return LocalizationSystem
