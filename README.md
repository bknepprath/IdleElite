# Idle Elite
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


A Godot 4 mobile idle RPG built around short sessions, table-driven activities, stamina rotation, mastery medals, offline progress, rewarded ads, and Android release builds.

Docs live in `docs/` and are maintained as Godot project references. Legacy HTML filenames are retained for link stability, but their contents should reflect the current Godot game. New agents should start with `docs/agent-codebase-map.md`, `docs/main-gd-ownership-map.md`, `docs/ui-runtime-boundary-map.md`, and `docs/activity-ui-boundary-map.md` before broad refactors.

## Codex Loop

Agent and automation rules live in `AGENTS.md`. In short: never call `Godot.exe` directly; use `.\run-godot-safe.ps1` or scripts that delegate to it.

Run a quick headless smoke test:

```powershell
.\scripts\check-project.ps1
```

Run a one-shot headless launch through the shared Godot safety wrapper:

```powershell
.\scripts\run-game.ps1
```

## Current Game Loop

- Pick a skill from the skill list.
- Skill rows use their skill icons so the main menu scans like a phone game menu.
- Pick one of that skill's unlocked actions.
- The selected action's progress bar fills repeatedly.
- Every completed bar gives XP, cash, and optional resources.
- Skill levels unlock better actions.
- Save data is written to Godot's local `user://idle_elite_save.json`.

## Skill Direction

The game is now organized around a shared action system instead of bespoke activity scenes.

Each skill has:

- A level and XP total.
- A list of table-driven actions.
- Unlock levels for stronger actions.
- A single progress bar loop for the current action.
- Standard rewards per completed action.

## Starter Fighting Progression

The first playable combat ladder uses plain regular animals:

| Unlock | Enemy | Role |
| ---: | --- | --- |
| Fighting Lv. 1 | Chicken | Fast, cheap tutorial target |
| Fighting Lv. 2 | Rat | First stamina step-up |
| Fighting Lv. 3 | Rabbit | Evasive small animal |
| Fighting Lv. 5 | Goat | Durable farm animal |
| Fighting Lv. 7 | Cow | First heavy animal wall |
| Fighting Lv. 9 | Pig | Expanded farm ladder |
| Fighting Lv. 11 | Sheep | Woolly stamina check |
| Fighting Lv. 13 | Goose | Noisy midgame step |
| Fighting Lv. 15 | Emu | Fast animal wall |
| Fighting Lv. 18 | Boar | Wild animal tier |
| Fighting Lv. 21 | Horse | Large animal tier |
| Fighting Lv. 24 | Bull | Heavy farm tier |
| Fighting Lv. 28 | Bear | First apex animal |

## Monetization Path

The Android/AdMob launch path is tracked in `play-store/docs/launch-runbook.md`.

Current status:

- Debug builds use Google's rewarded test ad unit ID.
- Release builds require real AdMob IDs before rewarded ads are enabled.
- The in-game ad button grants the +10% XP boost only from the rewarded callback on device.
- The latest release App Bundle is generated with a versioned filename, for example `builds/android/idle-elite-release-v0.1.2-code3.aab`.
