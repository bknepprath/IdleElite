# Agent Codebase Map

This map is the first stop for future agents working in Idle Elite. It explains where the major systems live, which files are source-of-truth, which files are generated or metadata, and which validation commands are safe on this machine.

## Start Here

- `AGENTS.md` is the process guardrail. Follow its Godot process safety rules before running any validation.
- `docs/agent-onboarding-checklist.md` is the quick first-ten-minutes checklist for new agent tasks.
- `scripts/main.gd` is the main gameplay, UI, save/load, networking, and presentation script. Use `docs/main-gd-ownership-map.md` before editing it.
- `docs/activity-database.json` is the activity database source of truth for both the Godot runtime and the HTTP-served docs page.
- `docs/activity-database-contract.md` explains how the source JSON, runtime loading, export filter, docs fetch path, and validation scripts relate.
- `docs/generated-file-hygiene.md` explains which generated files, Godot metadata, local outputs, caches, build folders, and secrets can be tracked or must stay local.
- `project.godot`, `export_presets.cfg`, and `assets/android/**` are externally referenced by Godot/Android export tooling. Treat paths there as compatibility-sensitive.
- `docs/asset-file-structure-audit.md` records the current asset naming and ownership audit. Read it before moving or deleting assets.
- `docs/ui-runtime-boundary-map.md` records stable navigation, home, shop, chat, leaderboard, and profile UI boundaries.
- `docs/activity-ui-boundary-map.md` records stable activity detail, action card, mastery, unlock, and offline summary boundaries.
- `docs/audio-structure-guide.md` records runtime audio assets, buses, player pools, music flow, settings, and sound-iteration guardrails.
- `docs/naming-audit.md` and the naming section in `AGENTS.md` describe the current rename rules.

## Runtime Structure

| Area | Main files and folders | Notes |
| --- | --- | --- |
| Main scene | `scenes/main.tscn`, `scripts/main.gd` | `main.tscn` binds the game to the large script. Avoid node-name or scene-bound path changes unless references are audited. |
| Extracted UI drawing helpers | `scripts/ui/*.gd` | These are runtime scripts preloaded by `scripts/main.gd`. Many have `.gd.uid` metadata; do not rename either side casually. |
| Shell UI boundaries | `docs/ui-runtime-boundary-map.md`, `scripts/check-ui-boundary-contracts.ps1` | Navigation, home, shop, chat, leaderboard, and profile still live in `scripts/main.gd`; use the map and contract check before refactoring those areas. |
| Activity UI boundaries | `docs/activity-ui-boundary-map.md`, `scripts/check-activity-ui-boundary-contracts.ps1` | Activity detail, action cards, mastery, unlocks, and offline summary still live in `scripts/main.gd`; use the map and contract check before refactoring those areas. |
| Activity data | `docs/activity-database.json`, `docs/activity-database.html`, `docs/activity-docs.js`, `docs/activity-database-contract.md`, `scripts/audit-activity-database.ps1`, `scripts/check-activity-database-contracts.ps1` | Edit JSON first, run the contract check and audit next; serve docs over HTTP for the HTML view. |
| Runtime art/audio | `assets/content/**`, `assets/loading/**`, `assets/android/**`, `assets/fonts/**`, `assets/music/**`, `assets/sfx/**` | Runtime paths are usually referenced as `res://assets/...` from code, docs data, presets, tests, or project settings. The former `assets/ui` split has been merged into `assets/content/ui`. Use `docs/audio-structure-guide.md` before changing shipped sound or music. |
| Art source/provenance | `docs/art-source/**` | Not runtime by default. This tree is under `.gdignore`; source PNGs and notes are tracked, while docs-side `.import` metadata should stay untracked unless future work proves it is needed provenance. |
| Release docs and outputs | `play-store/docs/**`, `builds/**`, `android/**` | Release artifacts and export-generated files are not general refactor surfaces. |
| Validation scripts | `scripts/check-project.ps1`, `scripts/test-*.ps1`, `scripts/check-*.ps1` | Prefer focused scripts first, then full project validation when practical. |

## Asset Ownership Rules

- Runtime assets live under `assets/`; source and selection history lives under `docs/art-source/`.
- Move tracked `.png` and matching `.png.import` files together. Search for the basename and full `res://` path before and after moves.
- Do not move `assets/loading/**` or `assets/android/**` as part of broad cleanup. Loading and launcher/export assets have project-level references.
- Keep `docs/activity-database.json` authoritative for runtime and docs data; do not introduce a second generated copy.
- Treat runtime `.gd.uid` and `.import` files as metadata-adjacent. They can be tracked and important even though Godot generates them. Docs-side `.import` files under `docs/art-source` are archive noise by default.
- Local output folders such as `.codex-tmp/`, `.codex-tools/`, `.godot/`, `output/`, and `test-results/` are not source unless a checklist explicitly adopts them.
- Do not add broad `*.import` or `*.uid` ignore rules; use `docs/generated-file-hygiene.md` and `.\scripts\check-generated-file-hygiene.ps1` before staging generated metadata.

## Validation Map

Use PowerShell from the repo root.

| Scope | Command | Use when |
| --- | --- | --- |
| Preferred full project gate | `.\scripts\check-project.ps1` | After meaningful runtime code, asset path, data, or validation-script changes. |
| One-shot Godot smoke | `.\run-godot-safe.ps1 --path . --quit-after 1` | When a quick Godot parser/startup check is enough. |
| Activity database contract | `.\scripts\check-activity-database-contracts.ps1` | After changing activity data, docs fetch code, runtime database paths, or export filters. |
| Activity database audit | `.\scripts\audit-activity-database.ps1` | After syncing activity data. |
| Generated-file hygiene contract | `.\scripts\check-generated-file-hygiene.ps1` | After changing `.gitignore`, generated-file docs, build-output docs, local config rules, `.import` rules, or `.uid` rules. |
| Save/load contracts | `.\scripts\test-save-normalization.ps1` | After save payload, restore, or serialized field changes. |
| Performance/static regression assertions | `.\scripts\test-performance-regressions.ps1` | After broad `main.gd`, asset-path, or validation contract changes. |
| Runtime asset path contract | `.\scripts\check-runtime-asset-paths.ps1` | After changing `res://assets` or `res://docs` paths in `project.godot`, `export_presets.cfg`, `scripts/main.gd`, boot UI scripts, or activity data. |
| UI boundary contract | `.\scripts\check-ui-boundary-contracts.ps1` | After editing navigation, home, shop, chat, leaderboard, or profile/avatar entry points. |
| Activity UI boundary contract | `.\scripts\check-activity-ui-boundary-contracts.ps1` | After editing activity detail, action cards, mastery medals, unlocks, lockpads, or offline summary entry points. |
| UI geometry/detail checks | `.\scripts\test-activity-card-geometry.ps1`, `.\scripts\test-skill-detail-bottom-scroll-pad.ps1`, `.\scripts\test-skill-detail-hidden-preview-scroll-gap.ps1` | After activity-card or skill-detail layout changes. |

Known baseline from the agent-readability checklist: `.\scripts\check-project.ps1` reaches the static/readability gates through `generated-file-hygiene-ok`, `ui-boundary-contracts-ok`, `activity-ui-boundary-contracts-ok`, and `leaderboard-cost-safety-ok`. In non-strict mode the skills-page performance gate retries intermittent scroll/swipe budget failures with a short warning; it prints the last failed sample only if all retries fail, then continues with `skills-page-performance-release-warning`. Record the exact current output if this behavior changes.

After every Godot command, check for leftover headless Godot processes. Only stop a process when it was launched by the validation command, is headless/non-interactive, and should have exited.

## Risky Paths

- `docs/activity-database.json`: shared source for the runtime loader and HTTP-served docs.
- `project.godot`: boot splash, autoload/project settings, Android settings.
- `export_presets.cfg`: package names, launcher paths, export filters, Android signing/export behavior.
- `assets/loading/**`: boot and loading presentation.
- `assets/android/**`: Android launcher and adaptive icon export paths.
- `assets/content/**`: runtime UI, activity, hub, achievement, fishing, thieving, event, and combo art.
- Save fields in `scripts/main.gd`: serialized keys must stay backward-compatible.
- Firebase leaderboard/chat config and rules: network schema and cost-safety checks protect this area.

## Common Safe First Moves

- Add or update docs that describe existing behavior.
- Add focused static assertions to `scripts/test-performance-regressions.ps1` or a narrower test when they protect a refactor.
- Rename local variables/functions only after checking references and avoiding serialized keys, data IDs, node names, signals, input names, and user-facing strings.
- Extract code only by one ownership area at a time, with a focused validation command and a small commit.
