# Idle Elite Module Rebuild Board
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Updated: 2026-06-16

Use this as the module design board. The cards should reflect the current game data unless a module is explicitly marked as new.

## Current Focus

**Five categories in columns. Design each category as a stack of modules.**

Current baseline:

```text
Fighting Lv 1: Shove Wobbly Hay Bale
Survivalism Lv 1: Gather Fallen Branches
Building Lv 1: Stack Bricks
Hunting Lv 1: Shallows
Wit Lv 1: Sleight of Hand
```

These names and values come from `docs/activity-database.json`.

## First Relationship Prototype

```text
Survivalism: Collect Logs #1
  type: Passive
  dependent: Logs

Building: Saw Planks
  type: Combo
  dependents: Collect Logs #1, Logs
```

Dependent modules appear as stacked ribbons above the module they relate to. Clicking the visible ribbon spreads the dependent stack open.

## Module Type Names

See `module-type-dictionary.html`.
