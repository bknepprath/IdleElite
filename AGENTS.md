# Agent Instructions

## Godot Process Safety

This project uses Godot and the machine can overheat if too many instances run at once.

- Never call `Godot.exe` directly; use `.\run-godot-safe.ps1` or a script that calls it.
- Use headless validation by default. Visible game-only playtesting requires an explicit request and `--visible-game`; never launch the editor/project manager, watch mode, or long-running processes.
- Keep at most 4 Godot processes running. The wrapper handles slot waiting and headless defaults.
- After each Godot command, verify no agent-owned headless process remains. Only terminate headless/non-interactive processes launched by that validation command; leave user windows alone and report unclear ownership.
- Preferred validation: `.\scripts\check-project.ps1`. For one-off commands, use `.\run-godot-safe.ps1 --path . --quit-after 1`.
- For player-visible changes, capture and visually inspect the real game at the dimensions being judged before presenting it. When confirming via screenshot, embed the exact inspected PNG inline in the final thread response and include its absolute path as supporting detail. Do not present mockups or helper renders as game screenshots, and reject art that spills outside its visible mask.
- Before a headless import, record `git status --short`; afterward use `git status --porcelain=v1` and restore only tracked `.import` files dirtied by that import.

## Mobile UI Readability

- Phone-visible text must be readable in a 1080px-wide portrait screenshot without zooming: body text at least 48px, help/status body text at least 52px, and titles at least 60px. If it does not fit, enlarge the container or shorten the copy; check wrapping and overlap in the rendered screenshot.

## Activity Database

- Edit `docs/activity-database.json` first, then follow `docs/activity-database-contract.md` for sync and audit steps. Fishing-specific area/order workflows live in `docs/fishing-rework-status.md`.

## Naming Conventions

- Use established Godot/GDScript style: `snake_case` for variables/functions/signals and `PascalCase` for preloaded class constants.
- Prefer human-readable, domain-accurate names; use lowercase kebab-case for grouped asset filenames.
- Do not rename serialized save keys, public data IDs, asset paths, node/signal/input names, localization strings, or other external references without compatibility handling. Inspect references with `rg` before renaming.

## Android Phone Debug Install

- Never uninstall `com.idleelite.game` without explicit approval for possible data loss; use `.\scripts\install-android-phone-debug.ps1` for the preview package `com.idleelite.game.preview`.

## Audio Safety

- Start new SFX below the regular UI cue volume, avoid stacking loud reward sounds, and validate the combined result in-game rather than only in solo playback.
