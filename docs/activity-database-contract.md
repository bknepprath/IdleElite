# Activity Database Contract

`docs/activity-database.json` is the source of truth for table-driven activity content. Runtime loading, documentation previews, export packaging, and validation all orbit this file.

## File Roles

| File | Role | Edit rule |
| --- | --- | --- |
| `docs/activity-database.json` | Authoritative source data for skills, actions, fishing areas, passive modules, art, backgrounds, unlocks, and generated categories. | Edit this first when changing activity data. |
| `docs/activity-database-data.js` | Generated JavaScript wrapper for local HTML previews. | Do not hand-edit. Regenerate with `python scripts\sync-activity-database-js.py`. |
| `scripts/sync-activity-database-js.py` | JSON-to-JS sync tool. | Keep the generated header clear and stable. |
| `scripts/audit-activity-database.ps1` | Structural/content audit for the source JSON and related runtime/export contracts. | Run after JSON changes and after sync. |
| `scripts/check-activity-database-contracts.ps1` | Fast source/generated ownership check. | Run when changing data, sync tooling, export filters, or runtime database loading. |
| `scripts/activity_data/catalog.gd` | Runtime catalog owner via `ACTIVITY_DATABASE_PATH`; owns live skill/action lookup collections. | The path must stay `res://docs/activity-database.json` unless runtime loading and exports move together. |
| `scripts/main.gd` | Public activity data aliases and compatibility wrappers. | Keep `skill_defs`, `actions_by_skill`, `actions_by_key`, and `convergence_action_ids` aliased to catalog-owned live collections until direct callers migrate. |
| `export_presets.cfg` | Android export include filter for the source JSON. | Must include `docs/activity-database.json` so exported builds can load the source data. |

## Required Change Flow

1. Edit `docs/activity-database.json`.
2. Run `python scripts\sync-activity-database-js.py`.
3. Run `.\scripts\check-activity-database-contracts.ps1`.
4. Run `.\scripts\audit-activity-database.ps1`.
5. Run focused runtime validation when the data affects a visible page or reward rule.

The generated JS should serialize the exact JSON payload, not a normalized or reordered copy. If a future tool intentionally changes serialization, update this contract and the check in the same commit.
