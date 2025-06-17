--[[
    Skill template definitions.

    Each entry describes a skill that the player can acquire. The
    fields are:
        * `name`     - display name for the skill
        * `rarity`   - drop rarity used by the gacha system
        * `image`    - Roblox asset id for the skill icon
        * `cooldown` - time in seconds before the skill can be used again
        * `damage`   - base damage dealt by the skill
        * `radius`   - effect radius in studs, if applicable
        * `effects`  - optional list of status effects applied on hit

    Additional fields can be appended as needed by gameplay systems.
]]

return {
    {
        name = "Fireball",
        rarity = "B",
        image = "rbxassetid://123456",
        cooldown = 3,
        damage = 10,
        radius = 4,
        effects = {"Burn"}
    },
    {
        name = "Lightning",
        rarity = "A",
        image = "rbxassetid://123457",
        cooldown = 5,
        damage = 15,
        radius = 5,
        effects = {"Shock"}
    },
    {
        name = "Ice Shard",
        rarity = "C",
        image = "rbxassetid://123458",
        cooldown = 4,
        damage = 8,
        radius = 3,
        effects = {"Slow"}
    }
}
