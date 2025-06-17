-- WaveConfig.lua
-- Specifies mobs to spawn for particular levels.

local WaveConfig = {
    levels = {
        [1] = {
            {type = "Goblin", count = 5}
        },
        [2] = {
            {type = "Goblin", count = 7}
        },
        [3] = {
            {type = "Goblin", count = 5},
            {type = "Ogre", count = 1}
        },
        [5] = {
            boss = "Ogre"
        },
        [10] = {
            boss = "Dragon"
        }
    }
}

return WaveConfig
