return {
    {id = "kill_10", event = "EnemyKilled", goal = 10,
        reward = {currency = "gold", amount = 5, tickets = {skill = 1}}},
    {id = "kill_50", event = "EnemyKilled", goal = 50,
        reward = {currency = "gold", amount = 25, tickets = {skill = 3, equipment = 1}}},
    {id = "boss_slayer", event = "BossKilled", goal = 1,
        reward = {crystals = 10, tickets = {companion = 1}}},
    {id = "dungeon_master", event = "DungeonComplete", goal = 3,
        reward = {keys = {location = 1}}},
    {id = "first_raid", event = "RaidComplete", goal = 1,
        reward = {keys = {raid = 1}}},
}
