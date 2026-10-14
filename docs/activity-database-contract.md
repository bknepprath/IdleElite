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

`unlock_drop` defines dedicated progression resources (`id`, `name`, integer `amount`, `icon`) produced on successful completion. These are not inventory currencies. Opening, resting, passive, Wisdom-only and arena activities do not receive these drops. Amounts currently increase with source level and remain prototype balance.

`unlock_project` version 2 retains stable project and step IDs and integer targets, but steps name a `resource` rather than requiring one specific activity. `source_skill`/`source_action` remain provenance and compatibility metadata. The runtime routes each unit to the earliest unfinished revealed compatible blocker (owner activity level order), carrying surplus forward without parallel duplication. Blocker clicks choose the highest current expected production rate among unlocked sources, using actual cycle time and success chance; equal rates favor higher levels. Resource icons are shared by activity families rather than assigned one per skill. `trail-marks` is the retained save/data ID for Resin; Rivets and Coins are additional resources. `unlock_project.material` selects timber, stone, iron, bronze, silver, gold, titanium, platinum or obsidian. These materials use shared ImageGen cover frames, holders and debris sprites. Portrait badges and blocker faces show icons and curved progress without numeric yields or fractions.

`activity_projects` save version 2 retains permanent counters. Version 1 success counters become equivalent resource credit without loss; old `materials` flags remain serialized for monotonic cloud comparisons. Project inventory costs have been removed. Do not rename project or step IDs without migration. Work/resources/Wisdom clear the illustrated barrier, then normal level and other access rules still apply. Old legitimate access is grandfathered. Run `scripts/tests/progression_prototype.gd` through the safe wrapper after progression changes; it delegates to the current production-scene resource test.

`mastery_xp_per_completion` is optional and defaults to 1. Resting activities use 10 to reduce completion requirements to approximately one tenth without changing saved mastery XP or levels. Arena activities (`combat.arena_shape = "diamond"`) do not earn mastery or count toward medal requirements.

1. Edit `docs/activity-database.json`.
2. Run `.\scripts\check-activity-database-contracts.ps1`.
3. Run `.\scripts\audit-activity-database.ps1`.
4. Run focused runtime validation when the data affects a visible page or reward rule.

For a local docs preview, run `python -m http.server` from the project root and open `http://localhost:8000/docs/activity-database.html`. The page fetches `docs/activity-database.json` through its existing relative fetch path; opening the HTML directly as `file://` cannot load the JSON in browsers that block local fetches.

Unlock-resource badges occupy the portrait top-right. Stored inventory drops retain bottom-left. Unlock resources appear only while a revealed progression blocker still needs that resource, independent of which skill is selected or which cards are currently mounted. Filling that resource requirement hides all matching badges, even if another resource or level gate remains. New revealed demand restores the badges. Hidden later projects do not receive surplus, and unused units are not banked. Allocation takes a revealed-target snapshot for each completion/batch so visibility changes during an award cannot grant resources to an unseen project. Availability refreshes are coalesced after progression/render changes; badges listen to one shared signal rather than polling every frame.


Halloween 2026: seasonal_events.halloween-2026 controls enabled and optional ends_at_unix (0 only for local iteration). seasonal_event marks the temporary Thieving activity; seasonal_unlock_drop adds a second direct blocker contribution without replacing unlock_drop. ProjectRuntime.drops_for exposes both. Seasonal activities are excluded from permanent mastery requirements. Historical seasonal save keys must remain preserved after their catalog entries are removed. Run scripts/tests/halloween_event.gd through the safe wrapper for this feature.
