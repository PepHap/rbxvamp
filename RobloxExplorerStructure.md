# Roblox Explorer Structure

This project expects the code and data modules in this repository to be imported into Roblox Studio using the following hierarchy.

## ServerScriptService
```
ServerScriptService
    src
        AutoBattleSystem (ModuleScript)
        CompanionSystem (ModuleScript)
        CurrencySystem (ModuleScript)
        EnemySystem (ModuleScript)
        GachaSystem (ModuleScript)
        GameManager (ModuleScript)
        ItemSystem (ModuleScript)
        KeySystem (ModuleScript)
        LevelSystem (ModuleScript)
        PlayerLevelSystem (ModuleScript)
        PlayerSystem (ModuleScript)
        QuestSystem (ModuleScript)
        RewardGaugeSystem (ModuleScript)
        SkillSystem (ModuleScript)
        SkillUISystem (ModuleScript)
        CompanionUISystem (ModuleScript)
        StatUpgradeSystem (ModuleScript)
        UISystem (ModuleScript)
        InventoryUISystem (ModuleScript)
    GameRunner (Script)
```

The `src` folder under `ServerScriptService` mirrors the `src` directory of this repository. Each Lua file becomes a `ModuleScript` with the same name.

`GameRunner` is a regular Script responsible for starting the game. Its main duties are:

```lua
local GameManager = require(script.src.GameManager)
GameManager:start()
GameManager.systems.AutoBattle:enable()

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)
```

## ReplicatedStorage
```
ReplicatedStorage
    assets
        companions (ModuleScript)
        item_upgrade_costs (ModuleScript)
        items (ModuleScript)
        skills (ModuleScript)
```

The `assets` folder mirrors this repository's `assets` directory. Converting each file into a `ModuleScript` allows the data to be shared between the server and potential client systems.

With this layout in place, modules can be required using paths like `ServerScriptService.src.GameManager` or `ReplicatedStorage.assets.items`.
