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
        [4] = {
            {type = "Skeleton", count = 6}
        },
        [5] = {
            boss = "Ogre"
        },
        [6] = {
            {type = "Goblin", count = 8},
            {type = "Skeleton", count = 2}
        },
        [7] = {
            {type = "Goblin", count = 9}
        },
        [8] = {
            {type = "Ogre", count = 2}
        },
        [9] = {
            {type = "Skeleton", count = 10}
        },
        [10] = {
            boss = "Dragon"
        },
        [11] = {
            {type = "Goblin", count = 10},
            {type = "Ogre", count = 1}
        },
        [12] = {
            {type = "Goblin", count = 10},
            {type = "Skeleton", count = 5}
        },
        [13] = {
            {type = "Skeleton", count = 10},
            {type = "Ogre", count = 1}
        },
        [14] = {
            {type = "Ogre", count = 2},
            {type = "Skeleton", count = 6}
        },
        [15] = {
            boss = "Ogre"
        },
        [20] = {
            boss = "Dragon"
        },
        [25] = {
            boss = "Ogre"
        },
        [30] = {
            boss = "Dragon"
        }
    }
}

return WaveConfig
