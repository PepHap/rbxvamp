# Roblox Vampire Survivors-like Game

This project aims to create a modular Roblox game inspired by Vampire Survivors.
The source code is organized inside the `src` folder using ModuleScripts for
major systems. Game assets should be placed under `assets`.

## Directory Structure
- `src/` – core game modules
- `assets/` – models, textures, and other resources

## Modules
- **GameManager.lua** – entry point and main loop
- **LevelSystem.lua** – handles level progression
- **ItemSystem.lua** – manages equipment items
- **SkillSystem.lua** – manages player skills and upgrades
- **CompanionSystem.lua** – companion acquisition and upgrades

## Usage
Import this repository into Roblox Studio and require the modules as needed.
Further gameplay features will be implemented incrementally.

### Example
```lua
local GameManager = require(path.to.GameManager)
local LevelSystem = require(path.to.LevelSystem)

GameManager:addSystem("Level", LevelSystem)
GameManager:start()
```
