return {
    Fireball = {
        {
            id = "power",
            name = "Power",
            steps = {
                {level = 5, changes = {damage = 5}},
                {level = 10, changes = {extraProjectiles = 1}}
            }
        },
        {
            id = "rapid",
            name = "Rapid",
            steps = {
                {level = 5, changes = {cooldown = -1}},
                {level = 10, changes = {cooldown = -1, radius = 1}}
            }
        }
    },
    Lightning = {
        {
            id = "power",
            name = "Power",
            steps = {
                {level = 5, changes = {damage = 5}}
            }
        }
    }
}
