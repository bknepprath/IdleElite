# Agent Instructions

## Godot Process Safety

This project uses Godot and the machine can overheat if too many instances run at once.

- Never call `Godot.exe` directly; use `.\run-godot-safe.ps1` or a script that calls it.
- Use headless validation by default. Visible game-only playtesting requires an explicit request and `--visible-game`; never launch the editor/project manager, watch mode, or long-running processes.
- Keep at most 4 Godot processes running. The wrapper handles slot waiting and headless defaults.
- After each Godot command, verify no agent-owned headless process remains. Only terminate headless/non-interactive processes launched by that validation command; leave user windows alone and report unclear ownership.
- Preferred validation: `.\scripts\check-project.ps1`. For one-off commands, use `.\run-godot-safe.ps1 --path . --quit-after 1`.
- For player-visible changes, capture and visually inspect the real game at the dimensions being judged before presenting it. "Real game" means the current project running `res://scenes/main.tscn` visibly through `.\run-godot-safe.ps1 --visible-game`, with the changed control reached through the actual game UI. Test-state setup may make the state deterministic, but the captured control must remain in its production scene hierarchy and screen.
- Never use an isolated control render, manually constructed capture layer, helper scene, hidden main scene, mockup, recreated UI, editor viewport, `SubViewport`, prior screenshot, or composited image as proof of a player-visible change.
- The submitted PNG must be the raw game viewport capture at the requested or judged pixel dimensions. Do not crop, resize, upscale, stretch, or composite it after capture. Verify the PNG's pixel dimensions before presenting it.
- If the real game does not boot, the target screen cannot be reached, the control is obscured, or capture times out, screenshot verification is blocked. Report that blocker and do not substitute any other render.
- When confirming via screenshot, embed the exact inspected PNG inline in the final thread response and include its absolute path as supporting detail. Reject art that spills outside its visible mask.
- For every player-visible change, the proof screenshot must show the exact changed control(s), tightly enough to judge the change. Do not use a broad or unrelated screen capture as proof. If the changed control is not visibly different or is not clearly present, keep iterating on the code and recapture until the screenshot provides definitive proof; embed that exact inspected PNG in the final response so the user can see it.
- For animation changes, capture raw frames from the same real-game run and viewport at the relevant before, transition, and settled states. Each frame must independently satisfy the real-game and pixel-dimension rules above.
- Before a headless import, record `git status --short`; afterward use `git status --porcelain=v1` and restore only tracked `.import` files dirtied by that import.

## Mobile UI Readability

- Phone-visible text must be readable in a 1080px-wide portrait screenshot without zooming: body text at least 48px, help/status body text at least 52px, and titles at least 60px. If it does not fit, enlarge the container or shorten the copy; check wrapping and overlap in the rendered screenshot.

## Android Rendering Safety

- Permanent screen-tearing rule: any tearing, split-frame bands, full-screen pixel corruption, or unstable canvas rendering on a physical phone is a hard release blocker. Stop immediately; do not accept, mask, defer, or ship it. Revert the responsible display/rendering change, restore the last known-good viewport configuration, and repeat physical-device validation before release work continues.
- Keep `project.godot` set to `window/stretch/mode="viewport"`. Do not change it to `canvas_items`; that setting has repeatedly caused severe full-screen pixel tearing in Play Store builds on physical Samsung phones.
- Headless, desktop, emulator, and automated checks cannot clear this risk by themselves. Final rendering acceptance requires the real Android build running without tearing on a physical Samsung phone.
- Treat any proposed change to the stretch mode, viewport size, stretch aspect, renderer, or Android graphics settings as a release-critical device change. Run `\.\scripts\check-crash-audit-contracts.ps1`, install the preview package with `\.\scripts\install-android-phone-debug.ps1`, and inspect the real game on a physical phone before accepting it.
- Every Android release must pass `\.\scripts\build-android-release.ps1`, which must refuse to export unless the stretch mode remains `viewport`. Do not bypass or remove that guard to make a build succeed.

## Animation Scale

- Never calculate animation-frame scale from measured alpha bounds, used rectangles, content height, transparent padding, or other per-frame image measurements.
- Give each character or animation one authored canonical draw box and ground anchor. Normalize source frames offline to that shared canvas and anchor.
- If an animation state intentionally changes size, use one explicit reviewed state scale. Do not apply runtime per-frame corrective scaling.
- Measured bounds may be used for grounding, positioning, cropping, masks, or hit testing, but never to determine visual scale.

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
