# Roblox Vampire Survivors-like Game

This project aims to create a modular Roblox game inspired by Vampire Survivors.
The source code is organized inside the `src` folder using ModuleScripts for
major systems. Game assets should be placed under `assets`.

## Directory Structure
- `src/` – core game modules
- `assets/` – models, textures, and other resources
- `tests/` – automated Busted test suites

## Modules
- **GameManager.lua** – entry point and main loop
- **LevelSystem.lua** – handles level progression
- **ItemSystem.lua** – manages equipment items
- **SkillSystem.lua** – manages player skills and upgrades
- **CompanionSystem.lua** – companion acquisition and upgrades
- **CompanionAttackSystem.lua** – companion follow and attack logic
- **DataPersistenceSystem.lua** – saves and loads player data
- **ThemeSystem.lua** – adjusts UI colors based on the current location
- **PartySystem.lua** – manages cooperative parties
- **RaidSystem.lua** – coordinates raid encounters for groups
- **TeleportSystem.lua** – teleports parties to lobby or raid places
- **EnemySystem.lua** – spawns foes with health and damage automatically
  scaled by the number of players in the server

## Installing Busted
This project uses the [Busted](https://olivinelabs.com/busted/) testing
framework. Install it on Debian-based systems with:

```bash
sudo apt-get install lua-busted
```

## Usage
Import this repository into Roblox Studio and require the modules as needed.
Further gameplay features will be implemented incrementally.

### Example
```lua
local GameManager = require(path.to.GameManager)
local LevelSystem = require(path.to.LevelSystem)

GameManager:addSystem("Level", LevelSystem)
GameManager:start()
GameManager.systems.AutoBattle:enable()

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    GameManager:update(dt)
end)
```

### Controls
Press **B** during gameplay to toggle the inventory UI. The player can also use
**K** to open skills, **L** for companions and **M** for the main menu.
Use the number keys **1**&ndash;**4** to cast the skills in your slots. When
the AutoSkill system is enabled, skills will fire automatically whenever they
are off cooldown.

Quest rewards now include raid keys which allow parties to initiate raid runs
through the **Party** interface. When the raid begins, the `TeleportSystem`
teleports all party members to the dedicated raid place using
`TeleportService:TeleportPartyAsync`.

### Syncing with Rojo
Install [Rojo](https://rojo.space/docs) and run the following command to sync
this repository with Roblox Studio using `default.project.json`:

```bash
rojo serve
```
This maps files such as `src/GameManager.lua` to
`ServerScriptService.src.GameManager` and places the `assets` folder under
`ReplicatedStorage.assets`.
## Testing
Run the repository checks via:

```bash
bash scripts/check.sh
```
This script executes the Busted test suite if it is installed and warns you if
the framework is missing. The tests live under the `tests/` directory.
