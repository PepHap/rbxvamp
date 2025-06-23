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
        module = "Fireball",
        cooldown = 3,
        damage = 10,
        radius = 4,
        effects = {"Burn"}
    },
    {
        name = "Lightning",
        rarity = "A",
        image = "rbxassetid://123457",
        module = "Lightning",
        cooldown = 5,
        damage = 15,
        radius = 5,
        effects = {"Shock"}
    },
    {
        name = "Ice Shard",
        rarity = "C",
        image = "rbxassetid://123458",
        module = "IceShard",
        cooldown = 4,
        damage = 8,
        radius = 3,
        effects = {"Slow"}
    },
    {
        name = "Wind Slash",
        rarity = "C",
        image = "rbxassetid://123459",
        module = "WindSlash",
        cooldown = 2,
        damage = 6,
        radius = 3,
        effects = {"Bleed"}
    },
    {
        name = "Arcane Burst",
        rarity = "S",
        image = "rbxassetid://123460",
        module = "ArcaneBurst",
        cooldown = 8,
        damage = 25,
        radius = 6,
        effects = {"Burn"}
    },
    {
        name = "Meteor Strike",
        rarity = "SS",
        image = "rbxassetid://123461",
        module = "MeteorStrike",
        cooldown = 12,
        damage = 40,
        radius = 8,
        effects = {"Burn"}
    },
    {
        name = "Earthquake",
        rarity = "B",
        image = "rbxassetid://123462",
        module = "Earthquake",
        cooldown = 10,
        damage = 30,
        radius = 7,
        effects = {"Stun"}
    },
    {
        name = "Ethereal Strike",
        rarity = "SS",
        image = "rbxassetid://123463",
        module = "EtherealStrike",
        cooldown = 6,
        damage = 50,
        radius = 5,
        effects = {"Pierce"}
    },
    {
        name = "Twin Shot",
        rarity = "B",
        image = "rbxassetid://123464",
        module = "TwinShot",
        cooldown = 4,
        damage = 8,
        radius = 4,
        effects = {"Pierce"}
  },
  {
        name = "Chain Lightning",
        rarity = "A",
        image = "rbxassetid://123464",
        module = "ChainLightning",
        cooldown = 7,
        damage = 18,
        radius = 6,
        effects = {"Shock"}
    },
    {
        name = "Shadow Flame",
        rarity = "S",
        image = "rbxassetid://123465",
        module = "ShadowFlame",
        cooldown = 6,
        damage = 20,
        radius = 4,
        effects = {"Burn"}
    },
    {
        name = "Frost Nova",
        rarity = "B",
        image = "rbxassetid://123466",
        module = "FrostNova",
        cooldown = 5,
        damage = 12,
        radius = 5,
        effects = {"Freeze"}
    },
}

