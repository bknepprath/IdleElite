# `scripts/main.gd` Ownership Map

`scripts/main.gd` is the central Godot script for Idle Elite. It currently owns runtime state, UI assembly, activity logic, save/load, Firebase networking, audio, and many style helpers. Use this map to find the right region before editing, then run focused reference searches around the exact symbols you change.

Line numbers are approximate and should be refreshed with `rg -n "^func _name|^var name|^const NAME" scripts\main.gd` before a risky edit.

## Top-Level Layout

| Region | Approx. lines | Owns | Refactor risk |
| --- | ---: | --- | --- |
| Preloads and drawn helper classes | 1-1079 | Preloaded `scripts/ui` classes, custom draw classes, constants for visuals and timing. | Medium. Preload path changes must update files, `.uid` metadata expectations, and validation. |
| Save/gameplay/asset constants | 1080-2170 | Save path/schema, activity DB path, UI art paths, hub constants, mastery constants, layout constants, leaderboard/chat constants. | High. Serialized keys, `res://` paths, and export-sensitive constants need compatibility checks. |
| Runtime state | 2184-2951 | Skills/actions, fishing, passive/convergence modules, hub, ads, nav, leaderboard, chat, profile, module UI prefs, audio, cache, save dirty flags. | High. State names can be safe internally, but saved fields and node references are not. |
| Lifecycle and frame loops | 2963-4729 | `_ready`, `_process`, `_input`, app suspend/resume, lazy detail window, background maintenance, stop-hold input. | High. Affects every page and mobile input behavior. |
| UI shell and Firebase setup | 4733-6180 | Root UI shell, async boot UI, HTTP request nodes, Firebase URL/auth, leaderboard fetch/submit, chat send/stream parsing. | High. Protected by leaderboard cost-safety/config tests and runtime guards. |
| Core screen builders | 6197-8036 | Boot warmup, achievement/tutorial overlays, home, skills page, nav bar, utility row, chat strip/overlay, settings/profile/achievements/offline overlays. | Medium-high. Visual regressions are easy; use targeted UI smoke tests when editing. |
| Skill detail caching/swipe/hub UI | 8036-14500 | Skill detail cache, swipe frame, hub tutorial/decor/module placement/detail panels, leaderboard page UI, chat/profile display helpers, skill menu cards. | High. Many cached controls and mobile gestures interact here. |
| Activity card and detail modules | 14500-18390 | Interactive action cards, lazy render plan, pinned/collapsed module UI, thieving heist cards and jail overlays. | High. Run activity-card/detail tests and inspect `module_ui_*` save helpers. |
| Fishing rework UI and mechanics | 18390-43198 | Fishing areas, methods, tools, collection, fluids, catch bursts, fishing action timing/rewards. | High. Activity database is the source of truth; sync/audit after data edits. |
| Save/load and offline progress | 43199-45033 | `_save_payload`, offline reward calculation, save load/recovery, restore helpers, secondary restore. | Very high. Protected by `test-save-normalization.ps1`; do not rename save keys without migration. |
| Progression, rewards, modules | 45145-48529 | Skill levels, leaderboard score categories, mastery medals/buffs, opportunity windows, convergence/passive processing, module UI save keys. | High. Gameplay math and save contracts live together. |
| Formatting, resources, styling, audio, cleanup | 48570-52097 | Number formatting, texture/image helpers, profile avatars, buttons, styleboxes, audio/music/SFX, transient cleanup. | Medium. Visual/audio changes need in-game validation; asset path helpers affect many systems. |

## Ownership By System

| System | Main symbols/regions | Existing validation to consider |
| --- | --- | --- |
| Activity database loading | `ACTIVITY_DATABASE_PATH`, `skills`, `skill_defs`, `actions_by_skill`, fishing area definitions | `python scripts\sync-activity-database-js.py`, `.\scripts\audit-activity-database.ps1`, `.\scripts\check-project.ps1` |
| Save/load | `SAVE_PATH`, `_save_payload`, `_load_game_core`, `_load_game_secondary_restore`, `_restore_*_from_save`, `*_for_save` | `.\scripts\test-save-normalization.ps1`, `.\scripts\test-performance-regressions.ps1`, `.\scripts\check-project.ps1` |
| Navigation and top-level pages | `_build_ui_shell`, `_build_home_page`, `_build_skills_page`, `_build_nav_bar`, `_nav_button`, `_show_*` helpers | `.\scripts\test-performance-regressions.ps1`, `.\scripts\test-tutorial-start-scroll.ps1`, `.\scripts\check-project.ps1` |
| Skill detail and swiping | `skill_swipe_*`, `_skill_detail_cache_*`, `_build_detail_*`, `_process_detail_lazy_window` | `.\scripts\test-skills-page-performance.ps1`, `.\scripts\test-skills-page-ablation.ps1`, `.\scripts\test-skill-detail-bottom-scroll-pad.ps1` |
| Activity cards and unlocks | `_build_detail_interactive_action_card`, `_activity_card_*`, `activity_unlock_*`, lockpad helpers | `.\scripts\test-activity-card-geometry.ps1`, `.\scripts\test-unlock-combo-visual-smoke.ps1`, `.\scripts\test-performance-regressions.ps1` |
| Fishing | `fishing_*`, `_fishing_*`, `selected_fishing_locations`, tool wallet and collection layers | Activity database sync/audit, `.\scripts\check-project.ps1`, focused visual/manual checks for fishing UI |
| Hub | `HUB_*`, `hub_*`, `_add_hub_*`, `_process_hub_modules`, `_hub_mission_*` | `.\scripts\check-project.ps1`; add focused assertions when extracting hub save/UI behavior |
| Passive/convergence modules | `passive_modules`, `convergence_modules`, `_process_passive_modules`, `_process_convergence_modules`, related save helpers | `.\scripts\test-save-normalization.ps1`, `.\scripts\test-performance-regressions.ps1` |
| Leaderboard/profile | `leaderboard_*`, `profile_*`, `_leaderboard_*`, `_profile_*` | `.\scripts\check-leaderboard-cost-safety.ps1`, `.\scripts\test-firebase-leaderboard-config-validation.ps1`, `.\scripts\test-firebase-leaderboard-runtime-guard.ps1` |
| Chat | `chat_*`, `_chat_*`, Firebase stream helpers, chat overlay/strip builders | `.\scripts\test-firebase-leaderboard-runtime-guard.ps1`, `.\scripts\check-project.ps1`; preserve rate-limit and auth behavior |
| Shop/ads | `ad_*`, `shop_*`, `_shop_ad_offer_button`, rewarded ad callbacks | Device validation for ads; do not change real/test ad behavior without release context |
| Audio | `_build_audio`, `_play_*`, `_process_music_flow`, audio stream caches | Audio safety in `AGENTS.md`; validate new sounds in game, not only by file existence |
| Asset paths and textures | `*_TEXTURE`, `_texture`, `_texture_or_visual_fallback`, `_action_card_background_texture`, `_hub_sheet_or_visual_fallback` | `rg` exact paths, `.\scripts\test-performance-regressions.ps1`, `.\scripts\check-project.ps1` |

## Safe Extraction Targets

These are good future extraction candidates because their names already form coherent ownership boundaries:

- Leaderboard/profile helpers: `_leaderboard_*`, `_profile_*`, and related state fields.
- Chat strip/overlay/stream helpers: `_chat_*` with Firebase URL helpers shared carefully.
- Hub module placement/detail/mission helpers: `_hub_*`, split by placement, detail panel, and missions.
- Module UI preferences: `module_ui_*`, pinned/collapsed/sort behavior, and save helpers.
- Formatting and style helpers: `_format_*`, `_paper_button_style*`, `_nav_style`, `_chat_*_style`, `_profile_*_style`.
- Asset path constants: group by runtime owner before moving into modules.

Do not start with broad extraction of `_process`, `_input`, save/load, or activity card construction. Those areas mix state lifetime, gestures, animation, save contracts, and UI caches.

## Rename Boundaries

Internal locals and private helpers can be renamed when references are clear. Do not rename these without compatibility handling:

- Save keys emitted by `_save_payload` or read by `_restore_*_from_save`.
- Public activity IDs, skill IDs, action IDs, fishing area IDs, module keys, and Firebase category keys.
- Godot node names, input actions, signal names, scene-bound paths, and user-facing strings.
- Asset paths referenced by `res://`, `project.godot`, `export_presets.cfg`, generated docs data, tests, or Play Store tooling.

## Before Editing Checklist

1. Search exact symbols and paths with `rg`.
2. Identify whether the change touches serialized data, generated data, runtime assets, or scene-bound paths.
3. Choose the narrowest focused validation script that protects the region.
4. Run `.\scripts\check-project.ps1` when practical after runtime-impacting changes.
5. Verify no headless Godot process remains after any Godot validation.
6. Record progress in the relevant checklist or status note before committing.
