-- Assets/menu_icons.lua
-- Таблица asset id-ов иконок для меню и кнопок HUD

local MenuIcons = {}

-- Основные иконки интерфейса
MenuIcons.Interface = {
    -- Основные кнопки HUD
    inventory = "rbxassetid://8560915132",      -- Рюкзак
    character = "rbxassetid://8560915047",      -- Персонаж
    skills = "rbxassetid://8560915089",         -- Звезда навыков
    equipment = "rbxassetid://8560915001",      -- Меч и щит
    quests = "rbxassetid://8560915156",         -- Свиток
    achievements = "rbxassetid://8560914931",   -- Трофей
    statistics = "rbxassetid://8560915178",     -- График
    settings = "rbxassetid://8560915198",       -- Шестерёнка

    -- Меню и навигация
    menu = "rbxassetid://8560915067",           -- Три полоски
    close = "rbxassetid://8560914965",          -- Крестик
    back = "rbxassetid://8560914947",           -- Стрелка назад
    forward = "rbxassetid://8560915023",        -- Стрелка вперёд
    home = "rbxassetid://8560915045",           -- Домик

    -- Социальные функции
    party = "rbxassetid://8560915112",          -- Группа людей
    friends = "rbxassetid://8560915025",        -- Сердце/люди
    chat = "rbxassetid://8560914963",           -- Пузырь чата
    mail = "rbxassetid://8560915065",           -- Конверт

    -- Игровые системы
    shop = "rbxassetid://8560915176",           -- Корзина покупок
    gacha = "rbxassetid://8560915027",          -- Игровой автомат
    dungeon = "rbxassetid://8560914985",        -- Замок/башня
    raid = "rbxassetid://8560915154",           -- Скрещённые мечи
    pvp = "rbxassetid://8560915134",            -- Щиты противников

    -- Прогресс и достижения
    level = "rbxassetid://8560915063",          -- Лестница/уровни
    progress = "rbxassetid://8560915130",       -- Прогресс-бар
    map = "rbxassetid://8560915071",            -- Карта мира
    compass = "rbxassetid://8560914967",        -- Компас

    -- Ресурсы и валюты
    gold = "rbxassetid://8560915039",           -- Золотая монета
    gems = "rbxassetid://8560915029",           -- Драгоценные камни
    crystals = "rbxassetid://8560914971",       -- Кристаллы
    souls = "rbxassetid://8560915174",          -- Души
    keys = "rbxassetid://8560915059",           -- Ключи
    energy = "rbxassetid://8560914989",         -- Молния/энергия

    -- Действия и взаимодействие
    plus = "rbxassetid://8560915128",           -- Плюс
    minus = "rbxassetid://8560915073",          -- Минус
    check = "rbxassetid://8560914961",          -- Галочка
    cross = "rbxassetid://8560914973",          -- Крестик
    lock = "rbxassetid://8560915061",           -- Замок
    unlock = "rbxassetid://8560915196",         -- Открытый замок

    -- Информация и помощь
    info = "rbxassetid://8560915049",           -- Информация (i)
    help = "rbxassetid://8560915043",           -- Знак вопроса
    warning = "rbxassetid://8560915200",        -- Предупреждение
    error = "rbxassetid://8560914987",          -- Ошибка

    -- Время и таймеры
    clock = "rbxassetid://8560914969",          -- Часы
    timer = "rbxassetid://8560915190",          -- Таймер
    hourglass = "rbxassetid://8560915047",      -- Песочные часы

    -- Звук и настройки
    sound_on = "rbxassetid://8560915172",       -- Звук включён
    sound_off = "rbxassetid://8560915170",      -- Звук выключен
    music_on = "rbxassetid://8560915075",       -- Музыка включена
    music_off = "rbxassetid://8560915077",      -- Музыка выключена
}

-- Иконки состояний и эффектов
MenuIcons.Status = {
    -- Базовые состояния
    health = "rbxassetid://8560915041",         -- Сердце
    mana = "rbxassetid://8560915069",           -- Капля маны
    stamina = "rbxassetid://8560915180",        -- Щит выносливости
    experience = "rbxassetid://8560914991",     -- Звезда опыта

    -- Бафы и дебафы
    buff_attack = "rbxassetid://8560914951",    -- Меч вверх
    buff_defense = "rbxassetid://8560914953",   -- Щит вверх
    buff_speed = "rbxassetid://8560914955",     -- Крылья
    buff_regen = "rbxassetid://8560915152",     -- Плюс в круге

    debuff_poison = "rbxassetid://8560914979", -- Череп яда
    debuff_curse = "rbxassetid://8560914975",  -- Проклятие
    debuff_slow = "rbxassetid://8560915168",   -- Цепи
    debuff_burn = "rbxassetid://8560914957",   -- Огонь

    -- Элементы и сопротивления
    fire = "rbxassetid://8560915015",           -- Огонь
    ice = "rbxassetid://8560915051",            -- Лёд
    lightning = "rbxassetid://8560915061",      -- Молния
    earth = "rbxassetid://8560914983",          -- Земля
    wind = "rbxassetid://8560915202",           -- Ветер
    dark = "rbxassetid://8560914977",           -- Тьма
    light = "rbxassetid://8560915061",          -- Свет

    -- Редкость предметов
    common = "rbxassetid://8560914967",         -- Серая звезда
    uncommon = "rbxassetid://8560915194",       -- Зелёная звезда
    rare = "rbxassetid://8560915150",           -- Синяя звезда
    epic = "rbxassetid://8560914993",           -- Фиолетовая звезда
    legendary = "rbxassetid://8560915057",      -- Золотая звезда
    mythic = "rbxassetid://8560915079",         -- Радужная звезда
}

-- Иконки навыков и способностей
MenuIcons.Skills = {
    -- Боевые навыки
    sword_mastery = "rbxassetid://8560915184",  -- Мастерство меча
    magic_mastery = "rbxassetid://8560915067",  -- Мастерство магии
    archery = "rbxassetid://8560914949",        -- Лук и стрела
    shield_mastery = "rbxassetid://8560915162", -- Мастерство щита

    -- Магические школы
    fire_magic = "rbxassetid://8560915017",     -- Огненная магия
    ice_magic = "rbxassetid://8560915053",      -- Ледяная магия
    lightning_magic = "rbxassetid://8560915063", -- Магия молний
    earth_magic = "rbxassetid://8560914985",    -- Магия земли
    healing_magic = "rbxassetid://8560915043",  -- Магия исцеления
    dark_magic = "rbxassetid://8560914979",     -- Тёмная магия

    -- Пассивные навыки
    toughness = "rbxassetid://8560915192",      -- Выносливость
    agility = "rbxassetid://8560914933",        -- Ловкость
    intelligence = "rbxassetid://8560915055",   -- Интеллект
    wisdom = "rbxassetid://8560915204",         -- Мудрость
    charisma = "rbxassetid://8560914959",       -- Харизма
    luck = "rbxassetid://8560915065",           -- Удача

    -- Специальные способности
    berserk = "rbxassetid://8560914955",        -- Берсерк
    stealth = "rbxassetid://8560915182",        -- Скрытность
    critical_hit = "rbxassetid://8560914973",   -- Критический удар
    dodge = "rbxassetid://8560914981",          -- Уклонение
    block = "rbxassetid://8560914957",          -- Блок
    parry = "rbxassetid://8560915114",          -- Парирование
}

-- Иконки интерфейсных элементов
MenuIcons.UI = {
    -- Кнопки действий
    accept = "rbxassetid://8560914931",         -- Принять
    decline = "rbxassetid://8560914977",        -- Отклонить
    confirm = "rbxassetid://8560914969",        -- Подтвердить
    cancel = "rbxassetid://8560914959",         -- Отменить

    -- Сортировка и фильтры
    sort_asc = "rbxassetid://8560915168",       -- Сортировка по возрастанию
    sort_desc = "rbxassetid://8560915170",      -- Сортировка по убыванию
    filter = "rbxassetid://8560915013",         -- Фильтр
    search = "rbxassetid://8560915160",         -- Поиск

    -- Управление списками
    list_view = "rbxassetid://8560915063",      -- Просмотр списком
    grid_view = "rbxassetid://8560915037",      -- Просмотр сеткой
    expand = "rbxassetid://8560914995",         -- Развернуть
    collapse = "rbxassetid://8560914965",       -- Свернуть

    -- Навигация по страницам
    first_page = "rbxassetid://8560915011",     -- Первая страница
    prev_page = "rbxassetid://8560915126",      -- Предыдущая страница
    next_page = "rbxassetid://8560915081",      -- Следующая страница
    last_page = "rbxassetid://8560915059",      -- Последняя страница

    -- Дополнительные элементы
    refresh = "rbxassetid://8560915148",        -- Обновить
    save = "rbxassetid://8560915158",           -- Сохранить
    load = "rbxassetid://8560915061",           -- Загрузить
    export = "rbxassetid://8560914997",         -- Экспорт
    import = "rbxassetid://8560915053",         -- Импорт
}

-- Функция для получения иконки по категории и имени
function MenuIcons.GetIcon(category, iconName)
    local categoryTable = MenuIcons[category]
    if categoryTable then
        return categoryTable[iconName]
    end

    -- Поиск по всем категориям, если не указана конкретная
    for _, cat in pairs(MenuIcons) do
        if type(cat) == "table" and cat[iconName] then
            return cat[iconName]
        end
    end

    warn("Иконка '" .. iconName .. "' не найдена в категории '" .. (category or "любой") .. "'")
    return MenuIcons.Interface.help -- Возвращаем иконку помощи как заглушку
end

-- Функция для проверки существования иконки
function MenuIcons.HasIcon(category, iconName)
    local categoryTable = MenuIcons[category]
    if categoryTable then
        return categoryTable[iconName] ~= nil
    end
    return false
end

-- Функция для получения всех иконок категории
function MenuIcons.GetCategoryIcons(category)
    return MenuIcons[category] or {}
end

-- Функция для получения списка всех категорий
function MenuIcons.GetCategories()
    local categories = {}
    for category, _ in pairs(MenuIcons) do
        if type(MenuIcons[category]) == "table" then
            table.insert(categories, category)
        end
    end
    return categories
end

return MenuIcons
