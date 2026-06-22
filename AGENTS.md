# Agent Instructions

## Godot Process Safety

This project uses Godot, and this machine can overheat if too many Godot instances run at once.

- Never call `Godot.exe` directly.
- Always launch Godot through `.\run-godot-safe.ps1`.
- Use headless Godot for automated validation by default.
- Visible game-only playtesting is allowed when the user explicitly asks to watch interactive testing. Launch visible playtests through `.\run-godot-safe.ps1 --visible-game --path .`; do not use visible mode for editor tasks.
- Do not launch the Godot editor UI or project manager.
- Do not use watch mode or long-running Godot processes.
- Across all agents combined, keep at most 4 Godot processes running at the same time.
- The wrapper waits up to 5 minutes for a slot. If no slot opens, continue with static analysis where possible and report that Godot validation is blocked.
- After every Godot command, verify no headless Godot process was left behind by that command. Only terminate Godot processes that were launched by the agent's validation command, are headless/non-interactive, and should have exited. Do not terminate a user-opened Godot editor, project manager, or visible game window. If ownership or headless status is unclear, leave the process running and report it instead of killing it.
- When working in Godot, verify the result with a screenshot whenever the change affects UI, visuals, layout, animation, scenes, or other player-visible behavior. Prefer automated screenshot capture through the safe wrapper or existing test scripts, and include/report the screenshot path with the validation notes.

Preferred validation:

```powershell
.\scripts\check-project.ps1
```

For one-off Godot commands, call the wrapper directly:

```powershell
.\run-godot-safe.ps1 --path . --quit-after 1
```

For visible game-only playtesting when explicitly requested:

```powershell
.\run-godot-safe.ps1 --visible-game --path .
```

## Godot Asset Import and Screenshot Safety

- Before running `.\run-godot-safe.ps1 --path . --import --quit`, record `git status --short`. A headless import can touch many existing `.import` files. Afterward, keep only the new/intentional asset metadata and clean unrelated import churn only if it is clearly from your import command, not pre-existing user work.
- When cleaning Godot import churn, use `git status --porcelain=v1` to find tracked `.import` files. Do not rely on `git diff -- '*.import'`; line-ending/stat-only changes may appear in `git status` even when `git diff` returns nothing. Restore only the specific tracked `.import` paths you just dirtied, never broad-reset the worktree.
- If a headless screenshot or validation script times out, inspect Godot command lines before killing anything:
  ```powershell
  Get-CimInstance Win32_Process -Filter "Name='Godot.exe'" | Select-Object ProcessId,ParentProcessId,CommandLine
  ```
  Stop only the headless process that clearly belongs to your wrapper-launched command and should have exited. Leave visible game/debug/editor/project-manager windows alone.
- For generated UI icons with a white subject on a white background, do not remove white globally; that will damage the subject. Use a border-connected flood fill or another method that removes only the connected background, then verify corner alpha and subject alpha before wiring the asset.
- PowerShell image/file scripts should use `(Resolve-Path <path>).Path` when passing paths into .NET APIs. Parenthesize arithmetic inside array literals, for example `@(0, ($height - 1))`, to avoid accidental parser/object-array errors.

## Mobile UI Readability

- Text in the phone UI is NEVER allowed to be tiny or desktop-scaled. If it needs to be read on a phone, it must be comfortably readable in a 1080px-wide portrait screenshot without zooming.
- For Godot UI, avoid font sizes below 48 for player-facing body text. Popover/help body text should usually be 52 or larger, with titles around 60 or larger. Only use smaller text for decorative/nonessential labels after verifying it is still readable on a phone screenshot.
- Info boxes, help popovers, tutorial boxes, and explanatory status panels must use at least 52px body text and at least 60px title text. If the text no longer fits, enlarge the popover/window or shorten the copy; do not shrink below the minimum.
- When adding or changing phone-visible text, check the rendered screenshot for readability, wrapping, and overlap. If the screenshot text looks remotely like fine print, increase the font and resize the container.

## Activity Database (fishing rework)

- Source of truth: `docs/activity-database.json` (`fishing.areas[]`, per-action `area`).
- After editing fishing data: `python scripts\sync-activity-database-js.py`, then `.\scripts\audit-activity-database.ps1`.
- Area tags / backgrounds: `python scripts\reorganize-fishing-areas.py` or `python scripts\fix-fishing-action-order.py`.
- Status doc: `docs/fishing-rework-status.md`.

## Naming Conventions

- Treat naming as architecture work, not cosmetic churn. Prefer human-readable, domain-accurate names that explain the game concept, UI role, state lifetime, or data contract.
- Preserve established Godot/GDScript style: `snake_case` for variables/functions/signals, `PascalCase` for preloaded class constants, and clear prefixes for related systems such as `skill_swipe_*`, `detail_lazy_*`, `activity_*`, `fishing_*`, and `module_ui_*`.
- Avoid generic names like `item`, `data`, `info`, `tmp`, `thing`, `obj`, or `value` when the value has a real role. Use names such as `lazy_entry`, `activity_def`, `area_def`, `action_id`, `track_id`, `cached_root`, or `render_record` when those roles are accurate.
- Do not rename serialized save keys, public data IDs, asset paths, node names, signal names, input/action names, localization/user-facing strings, or externally referenced strings unless compatibility handling is added and validated.
- Before committing a rename, inspect references with `rg`, update nearby regression assertions when useful, keep the commit scoped to one naming concept, and avoid mixing behavior changes into rename-only commits.

## Android phone debug install

- Do not uninstall `com.idleelite.game` unless the user explicitly accepts data loss.
- Use `.\scripts\install-android-phone-debug.ps1` to export and install **Idle Elite Preview** (`com.idleelite.game.preview`) on a USB-connected device.

## Audio Safety

- Never add or wire a new SFX at full blast.
- New SFX should start quieter than the regular UI cue they accompany, especially if they are rare, layered, or celebratory.
- Avoid stacking multiple full-volume reward sounds on the same event.
- Validate new sounds as they will be heard in-game, not only as solo audition clips.
