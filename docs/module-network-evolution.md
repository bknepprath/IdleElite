# Module Relationships
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Updated: 2026-06-16

## Goal

Make skills depend on each other in simple, visible ways.

## First Chain

```text
Woodcutting -> logs
logs -> Building
Building -> Fishing pier
Fishing pier -> better fish
fish -> stamina help
```

## First Slice

Make three cards explain their relationship:

| Card | Relationship |
| --- | --- |
| Woodcutting passive logs | `Produces Logs` |
| Building: Saw Planks | `Uses Logs` |
| Building: Construct Fishing Pier | `Improves Pier Fishing` |

Do not build the full graph yet.

## UI Rule

Each card can show up to two relationship chips.

Examples:

- `Produces Logs`
- `Uses Logs`
- `Improves Pier`
- `Needs Fishing Lv 10`
- `Boosted by Barn`

Tap a chip for one short explanation.

## Skill Jobs

| Skill | Job |
| --- | --- |
| Woodcutting | Makes materials. |
| Building | Turns materials into permanent improvements. |
| Fishing | Makes fish and stamina help. |
| Fighting | Clears danger. |
| Thieving | Finds shortcuts. |

## Not Yet

- No full-screen graph.
- No big inventory.
- No hard lock maze.
- No new resource pile unless it has a clear sink.

## Validate

Ask one question after the first slice:

> Does the player understand why chopping logs helps fishing?

Then run:

```powershell
.\scripts\check-project.ps1
```
