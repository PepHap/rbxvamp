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

### Interface
All user interface comes from **gui.rbxmx**. During startup
`StarterGui/UILoader.client.lua` requires the `GeneratedGui` module which
creates a [`ScreenGui`](https://create.roblox.com/docs/reference/engine/classes/ScreenGui)
and populates it with instances described in the XML file. No legacy UI modules
remain and there are no keybinds for toggling windows.

To rebuild the Lua module after editing `gui.rbxmx`, run:

```bash
lua scripts/generate_gui.lua
```
This converts the XML into `src/GeneratedGui.lua` so the game loads the
interface without parsing XML at runtime.

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

### Rotating RemoteEvent Names
To obfuscate networking calls each major update, increment all RemoteEvent
version suffixes using:

```bash
lua scripts/rotate_events.lua
```
This rewrites `src/RemoteEventNames.lua` with the next version number so you can
re-publish the place with fresh RemoteEvent identifiers.

## Server Log
Currency and item transactions are recorded in `server-log/log.txt`. Suspicious
entries are flagged when exceeding configured limits. The log file is created
automatically when running the game outside of Roblox.
