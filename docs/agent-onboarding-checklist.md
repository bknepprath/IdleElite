# Agent Onboarding Checklist

Use this page when opening a fresh Idle Elite task. It is a quick operational checklist, not a replacement for the ownership maps.

## First Ten Minutes

1. Read `AGENTS.md` before running validation. Godot must go through `.\run-godot-safe.ps1` or project scripts that use it.
2. Run `git status --short` and identify unrelated dirty files before editing. Preserve user or prior-agent work that is not part of your package.
3. Start with `docs/agent-codebase-map.md`, then open the narrower map for the area you will touch:
   - `docs/main-gd-ownership-map.md` for `scripts/main.gd`.
   - `docs/ui-runtime-boundary-map.md` for home, navigation, shop, chat, leaderboard, or profile UI.
   - `docs/activity-ui-boundary-map.md` for activity detail, action cards, mastery, unlocks, or offline summary.
   - `docs/activity-database-contract.md` for activity data.
   - `docs/generated-file-hygiene.md` for `.import`, `.uid`, output, build, cache, or local config files.
4. Search references with `rg` before moving or renaming files, symbols, data IDs, or paths.
5. Pick the narrowest focused validation command before editing so you know what will prove the package.

## Source Of Truth Rules

- Activity data starts in `docs/activity-database.json`; regenerate `docs/activity-database-data.js` with `python scripts\sync-activity-database-js.py`.
- Runtime assets live under `assets/`; source and provenance assets live under `docs/art-source/`.
- Runtime asset `.import` files can be required metadata. Docs-side `.import` files under `docs/art-source/**` should stay out of git.
- `scripts/main.gd` still owns most runtime behavior. Use the ownership map and keep changes to one boundary at a time.
- `project.godot`, `export_presets.cfg`, launcher icons, boot/loading assets, save keys, Firebase rules, and public data IDs are compatibility-sensitive.

## Validation Flow

Run the most relevant focused gate first:

- `.\scripts\check-runtime-asset-paths.ps1` for runtime asset path changes.
- `.\scripts\check-activity-database-contracts.ps1` and `.\scripts\audit-activity-database.ps1` for activity data changes.
- `.\scripts\check-generated-file-hygiene.ps1` for generated-file, `.import`, `.uid`, output, build, cache, or local-config rule changes.
- `.\scripts\check-ui-boundary-contracts.ps1` for shell UI boundary edits.
- `.\scripts\check-activity-ui-boundary-contracts.ps1` for activity UI boundary edits.
- `.\scripts\test-save-normalization.ps1` for save/load changes.
- `.\scripts\test-performance-regressions.ps1` for broad `main.gd`, validation-contract, or performance-sensitive edits.

Then run `.\scripts\check-project.ps1` when practical. The current known baseline reaches the readability/static gates and may fail later in `.\scripts\test-skills-page-performance.ps1` on the existing build swipe performance budget. Always record the exact blocker if it changes.

After every Godot validation, sweep for leftover headless processes:

```powershell
Get-CimInstance Win32_Process -Filter "name like 'Godot%'" | Where-Object { $_.CommandLine -match '--headless' } | Select-Object ProcessId,Name,CommandLine
```

Only terminate a process when it clearly belongs to your validation command, is headless/non-interactive, and should have exited.

## Commit Rules

- Commit one coherent work package at a time.
- Stage only files owned by the package. Avoid `git add -A` when unrelated dirty files exist.
- Update docs, metadata, tests, and generated files together when the package owns those relationships.
- Record progress in the active checklist or linked status note before committing.
- Push the current branch after each package.

## Remaining High-Risk Areas

Do not rename or move these without deeper compatibility work and focused validation:

- Save keys and restore helpers in `scripts/main.gd`.
- Skill IDs, action IDs, fishing area IDs, module keys, Firebase category keys, and any public data ID in `docs/activity-database.json`.
- Godot node names, input actions, signal names, scene-bound paths, and user-facing strings.
- `project.godot`, `export_presets.cfg`, `assets/loading/**`, and `assets/android/**`.
- Firebase leaderboard/chat rules, local config expectations, and release signing/export behavior.
- Activity card construction, lazy-render plans, skill swipe behavior, and offline reward math.
