# Activity Database Contract

`docs/activity-database.json` is the source of truth for table-driven activity content. Runtime loading, documentation previews, export packaging, and validation all read or validate this file.

## File Roles

| File | Role | Edit rule |
| --- | --- | --- |
| `docs/activity-database.json` | Authoritative source data for skills, actions, fishing areas, passive modules, art, backgrounds, unlocks, and generated categories. | Edit this first when changing activity data. |
| `scripts/audit-activity-database.ps1` | Structural/content audit for the source JSON and related runtime/export contracts. | Run after JSON or loader changes. |
| `scripts/check-activity-database-contracts.ps1` | Fast source, runtime-loader, export, and docs-fetch check. | Run when changing data, export filters, runtime database loading, or the activity docs page. |
| `docs/activity-database.html` and `docs/activity-docs.js` | HTTP-served documentation view of the source JSON. | Serve the project root over HTTP before opening the page. |
| `scripts/activity_data/catalog.gd` | Runtime catalog owner via `ACTIVITY_DATABASE_PATH`; owns live skill/action lookup collections. | The path must stay `res://docs/activity-database.json` unless runtime loading and exports move together. |
| `scripts/main.gd` | Public activity data aliases and compatibility wrappers. | Keep `skill_defs`, `actions_by_skill`, `actions_by_key`, and `convergence_action_ids` aliased to catalog-owned live collections until direct callers migrate. |
| `export_presets.cfg` | Android export include filter for the source JSON. | Must include `docs/activity-database.json` so exported builds can load the source data. |

## Required Change Flow

1. Edit `docs/activity-database.json`.
2. Run `.\scripts\check-activity-database-contracts.ps1`.
3. Run `.\scripts\audit-activity-database.ps1`.
4. Run focused runtime validation when the data affects a visible page or reward rule.

For a local docs preview, run `python -m http.server` from the project root and open `http://localhost:8000/docs/activity-database.html`. The page fetches `docs/activity-database.json` through its existing relative fetch path; opening the HTML directly as `file://` cannot load the JSON in browsers that block local fetches.
