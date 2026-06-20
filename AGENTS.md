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
