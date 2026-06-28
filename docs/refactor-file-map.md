# Idle Slop 1 Refactor Map

Last updated: 2026-06-28

Purpose: living sidecar for the refactor. Keep this file updated when code moves, files are extracted, or session-touched files change.

Legend:
- `*` affected this session
- `(collapsed)` media/generated-heavy tree; counted by file count instead of line-by-line

## Session Notes

- Current main target: delete provably dead `scripts/main.gd` code, not just move it.
- Active extraction rule: only extract repeated code with a real second caller or a clear ownership boundary.
- Current known visual regression check: `scripts/test-page-switch-cover-visual.ps1` is failing on page-switch depressed-state assertions; leave page-switch press handling bespoke until that is understood.
- Prior UI fix this session: activity modules are clipped below the skill info shelf again.

## Top-Level Tree

| Path | Lines / Files | What lives here |
| --- | ---: | --- |
| `AGENTS.md` | 66 lines | Local agent safety rules, especially Godot launch and screenshot requirements. |
| `README.md` | 69 lines | Project overview and basic run/export notes. |
| `project.godot` | 35 lines | Godot project config and desktop/mobile viewport setup. |
| `run-godot-safe.ps1` | 197 lines | Required Godot launcher wrapper; use this instead of `Godot.exe`. |
| `export_presets.cfg` | 267 lines | Godot export presets. |
| `scenes/main.tscn` | 10 lines | Root scene that attaches the main script. |
| `scripts/` | 196 files / about 111,672 text lines | Game runtime script, UI drawing helpers, validation, build, and maintenance scripts. |
| `docs/` | 1,508 files (collapsed) | Design docs, audits, data viewers, generated art-source records. |
| `assets/` | 1,089 files (collapsed) | Runtime art, sound candidates, Godot import metadata. |
| `addons/` | 333 files (collapsed) | Third-party Godot addons, mainly AdMob. |
| `android/` | 74 files (collapsed) | Android platform/export support files. |
| `ios/` | 23 files (collapsed) | iOS plugin/export support files. |
| `play-store/` | 52 files (collapsed) | Store docs and release assets. |
| `public/` | 2 files | Web export/static hosting shell. |
| `firebase.json` | 28 lines | Firebase hosting/database config. |
| `firebase-realtime-database.rules.json` | 237 lines | Leaderboard/chat database rules. |

## Runtime Code

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/main.gd` * | 66,927 | Monolithic game controller: save/load, activity data, skill UI, navigation, fishing, leaderboard, chat, hub, audio, and most orchestration. Primary deletion/refactor target; recent UI drawing controls now preload from `scripts/ui/`. |
| `scripts/perf_monitor.gd` | 206 | Runtime performance monitor. |
| `scripts/activity_lock_rig.gd` | 1,141 | Activity lock rig drawing/animation support. |
| `scripts/activity_lock_cluster.gd` | 550 | Activity lock cluster rendering. |
| `scripts/activity_lock_number.gd` | 30 | Activity lock number rendering. |
| `scripts/fishing_attempt_bar.gd` | 145 | Fishing attempt progress/control drawing. |
| `scripts/fishing_fluid_strip.gd` | 276 | Fishing fluid strip visual. |
| `scripts/fishing_fluid_strip.gdshader` | 50 | Fishing strip shader. |
| `scripts/fishing_fluid_strip_underlay.gdshader` | 34 | Fishing strip underlay shader. |

## UI Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/ui/mobile_scroll_container.gd` | 515 | Mobile-friendly scroll behavior. |
| `scripts/ui/button_press_state.gd` * | 54 | Shared press/drag/release metadata helper for passive button routing. Extracted from `scripts/main.gd` this session. |
| `scripts/ui/regen_circle.gd` * | 662 | Extracted stamina/regen gauge drawing class used by skill headers, pinned shelves, and detail stamina gauges. |
| `scripts/ui/fish_circle.gd` * | 478 | Extracted fishing header currency/tool/wallet circle control. |
| `scripts/ui/page_switch_button_face.gd` * | 129 | Extracted page-switch/action-card shaped face drawing control. |
| `scripts/ui/prism_connector_overlay.gd` * | 241 | Extracted prism/depth connector drawing control. |
| `scripts/ui/page_switch_chevron_icon.gd` * | 54 | Extracted page-switch chevron icon drawing control. |
| `scripts/ui/module_utility_collapse_arrow.gd` * | 33 | Extracted module utility collapse arrow drawing control. |
| `scripts/ui/blue_guy_health_heart_gauge.gd` * | 82 | Extracted fight header health/regen heart gauge control. |
| `scripts/ui/blue_guy_chicken_brawl_stage.gd` | 1,689 | Fighting/chicken brawl stage visual. |
| `scripts/ui/activity_card_depth.gd` | 326 | Activity card pressed/elevation visual. |
| `scripts/ui/activity_card_border.gd` | 34 | Activity card border drawing. |
| `scripts/ui/activity_progress_rail.gd` | 267 | Activity progress rail drawing. |
| `scripts/ui/activity_progress_opportunity_overlay.gd` | 195 | Opportunity overlay drawing. |
| `scripts/ui/action_art_texture_rect.gd` | 178 | Action art texture display helper. |
| `scripts/ui/action_art_animation_rect.gd` | 243 | Animated action art display helper. |
| `scripts/ui/skill_detail_gradient_shelf.gd` | 21 | Skill detail shelf gradient. |
| `scripts/ui/skill_detail_page_shelf_shadow.gd` | 28 | Skill detail shelf shadow. |
| `scripts/ui/skill_menu_panel_chrome.gd` | 54 | Skill menu chrome drawing. |
| `scripts/ui/stop_hold_circle.gd` | 22 | Stop-hold progress circle. |
| `scripts/ui/fighting_module_stage.gd` | 31 | Fighting module stage wrapper. |
| `scripts/ui/firepit_flame_fx.gd` | 160 | Firepit flame visual. |
| `scripts/ui/firepit_fuel_ring.gd` | 141 | Firepit fuel ring drawing. |
| `scripts/ui/firepit_warmth_overlay.gd` | 66 | Firepit warmth overlay. |
| `scripts/ui/firepit_dependency_connector.gd` | 23 | Firepit dependency connector visual. |
| `scripts/ui/fishing_tool_wallet_overlay.gd` | 111 | Fishing tool wallet overlay. |
| `scripts/ui/convergence_multi_progress_bar.gd` | 192 | Convergence progress bar drawing. |
| `scripts/ui/clean_progress_bar.gd` | 80 | Shared clean progress bar drawing. |
| `scripts/ui/boot_flex_loading_animation.gd` | 270 | Boot loading animation. |
| `scripts/ui/hub_path_dots.gd` | 372 | Hub path/dot visual. |
| `scripts/ui/hub_build_progress_bar.gd` | 24 | Hub build progress bar. |
| `scripts/ui/hub_move_icon.gd` | 17 | Hub move icon. |
| `scripts/ui/mission_cooldown_ring.gd` | 19 | Mission cooldown ring. |
| `scripts/ui/organic_leaderboard_border.gd` | 44 | Leaderboard border. |
| `scripts/ui/passive_serpentine_progress_bar.gd` | 165 | Passive module progress bar. |
| `scripts/ui/passive_module_card_border.gd` | 30 | Passive module border. |
| `scripts/ui/passive_icon_sprite.gd` | 37 | Passive icon sprite helper. |
| `scripts/ui/passive_log_pile_sprite.gd` | 52 | Passive log pile sprite helper. |
| `scripts/ui/passive_pile_shadow.gd` | 22 | Passive pile shadow. |
| `scripts/ui/rounded_texture_rect.gd` | 276 | Rounded texture rect drawing. |
| `scripts/ui/rounded_corner_crop_overlay.gd` | 20 | Rounded corner crop overlay. |
| `scripts/ui/shop_ad_stack_light.gd` | 58 | Shop ad stack light visual. |
| `scripts/ui/feathered_collect_glow.gd` | 19 | Collect glow visual. |
| `scripts/ui/achievement_medal_slot_strip.gd` | 101 | Achievement medal strip. |

## Validation And Tooling

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/check-project.ps1` | 381 | Preferred broad project validation entrypoint. |
| `scripts/test-performance-regressions.ps1` * | 3,024 | Static/runtime regression assertions for performance-sensitive code and UI contracts; stale dead-helper preservation assertions removed. |
| `scripts/test-save-normalization.ps1` * | 2,671 | Save/load normalization regression assertions. |
| `scripts/test-module-list-transitions.ps1` | 3,289 | Module list transition behavioral validation. |
| `scripts/test-page-switch-cover-visual.ps1` | 375 | Page-switch cover/depressed visual validation. Currently failing in this session. |
| `scripts/check-ui-boundary-contracts.ps1` * | 96 | UI boundary static contracts. |
| `scripts/check-activity-ui-boundary-contracts.ps1` * | 59 | Activity UI boundary contracts. |
| `scripts/check-activity-database-contracts.ps1` | 48 | Activity database static contracts. |
| `scripts/audit-activity-database.ps1` | 870 | Activity database audit. |
| `scripts/capture-woodcutting-firepit.ps1` | 482 | Screenshot capture for firepit/skill-detail layout. |
| `scripts/check-leaderboard-cost-safety.ps1` * | 371 | Leaderboard cost and safety assertions. |
| `scripts/test-everything.ps1` | 213 | Broad validation orchestrator. |
| `scripts/lib/godot-processes.ps1` | 20 | Godot process helper functions. |

## Data And Docs

| Path | Lines | What lives here |
| --- | ---: | --- |
| `docs/activity-database.json` | 3,947 | Source of truth for skills, actions, modules, and fishing areas. |
| `docs/activity-database-data.js` | 3,949 | Generated JS mirror of activity database. |
| `docs/activity-database-contract.md` | 19 | Activity database contract notes. |
| `docs/activity-ui-boundary-map.md` | 17 | Activity UI ownership map. |
| `docs/ui-runtime-boundary-map.md` | 17 | UI/runtime ownership map. |
| `docs/main-gd-ownership-map.md` | 56 | Existing ownership map for `scripts/main.gd`. |
| `docs/agent-codebase-map.md` | 67 | Existing agent-facing codebase map. |
| `docs/ponytail-line-reductions.md` | 8 | Existing untracked line-reduction notes. |
| `docs/plan-v0.5.0.md` * | 209 | Version plan notes. Pre-existing changed file. |
| `docs/plan-v0.5.0.html` * | 482 | Rendered version plan. Pre-existing changed file. |
| `docs/refactor-file-map.md` * | this file | This living refactor map. |

## Session-Affected Files

| Path | Status | Notes |
| --- | --- | --- |
| `scripts/main.gd` | modified | Shared button press-state helpers extracted; several local UI drawing classes moved behind preloads; dead helper functions deleted. |
| `scripts/ui/button_press_state.gd` | added | New extracted helper for button press-state metadata, including optional extra metadata fields. |
| `scripts/ui/regen_circle.gd` | added | New extracted stamina/regen gauge drawing class. |
| `scripts/ui/fish_circle.gd` | added | New extracted fishing header circle control. |
| `scripts/ui/page_switch_button_face.gd` | added | New extracted shaped page-switch/action-card face control. |
| `scripts/ui/prism_connector_overlay.gd` | added | New extracted prism/depth connector overlay control. |
| `scripts/ui/page_switch_chevron_icon.gd` | added | New extracted page-switch chevron icon control. |
| `scripts/ui/module_utility_collapse_arrow.gd` | added | New extracted module utility collapse arrow control. |
| `scripts/ui/blue_guy_health_heart_gauge.gd` | added | New extracted fighting health heart gauge control. |
| `scripts/test-performance-regressions.ps1` | modified | Static assertion updated so skill detail action viewport must clip below the skill info shelf; RegenCircle and FishCircle assertions now target extracted scripts. Also contains pre-existing save/refactor assertion edits from active worktree. |
| `scripts/check-ui-boundary-contracts.ps1` | modified | Chat presentation boundary now tracks the live expanded composer instead of deleted `_chat_composer`. |
| `scripts/check-activity-ui-boundary-contracts.ps1` | modified | Unlock boundary no longer preserves deleted test-only `_unlock_prior_test_actions` listing. |
| `docs/ui-runtime-boundary-map.md` | modified | Chat boundary updated for live composer helper. |
| `docs/activity-ui-boundary-map.md` | modified | Unlock boundary map no longer lists deleted test helper. |
| `scripts/test-save-normalization.ps1` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `scripts/check-leaderboard-cost-safety.ps1` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.md` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.html` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/ponytail-line-reductions.md` | untracked | Pre-existing line-reduction notes. |
| `docs/refactor-file-map.md` | added | New live architecture/refactor sidecar. |

## Extraction Queue

0. Dead-code deletion
   - Current: deleted stale helpers `_build_hero`, `_add_hub_build_mode_toggle`, `_chat_composer`, `_detail_lazy_mount_initial_window_async`, `_render_detail_eager_card_list`, `_show_module_pin_preview`, `_build_skill_strip`, `_wait_for_page_switch_cover_opaque`, `_activity_stat_hit_buttons`, `_ensure_skill_swipe_preview`, `_capture_skill_strip_page_refs`, `_unlock_prior_test_actions`, `_chat_row`, `_sync_hub_hotspot_hold_circle`, `_hub_build_mode_button_style`, `_toggle_hub_build_mode`, `_expire_module_pin_preview_after_delay`, `_finish_module_pin_preview_animation`, `_prime_skill_swipe_preview_modules`, `_icon_button`, `_event_hourglass_badge`, `_fishing_wallet_selectable_tools`, `_summary_style`, `_thieving_heist_preceding_action_unlocked`, `_set_control_position_y_safe`, and `_position_new_onboarding_explore_tip`.
   - Next lazy win: continue only with functions that have no runtime/test callers after checking dynamic `scene.call(...)` use.

1. Button press state
   - Current: shared metadata helper lives in `scripts/ui/button_press_state.gd`; bottom nav, module utility, fishing offer, fishing method, and thieving heist buttons use it.
   - Next lazy win: keep page-switch separate until its visual regression is understood.

2. Activity/skill UI ownership
   - Current: many shelf, module, card, and action rendering paths still live in `scripts/main.gd`; the reusable local drawing controls larger than tiny glyphs are now isolated in `scripts/ui/`.
   - Next lazy win: skip the remaining 8-45 line local glyph helpers unless they need real behavior changes; extracting them would add more file plumbing than architecture.

3. Save normalization
   - Current: many tiny save helper wrappers have been inlined or renamed in active worktree changes.
   - Next lazy win: keep exact static tests around any save-payload simplification.

4. Activity database
   - Current: data source is already externalized in `docs/activity-database.json`.
   - Next lazy win: do not move data again; reduce loader glue in `scripts/main.gd` instead.

## Validation Log

| Step | Result |
| --- | --- |
| `git diff --check -- scripts/main.gd scripts/ui/button_press_state.gd docs/refactor-file-map.md` | passed. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting `scripts/ui/button_press_state.gd`. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting `scripts/ui/button_press_state.gd`. |
| `.\scripts\test-module-list-transitions.ps1` | passed after extracting `scripts/ui/button_press_state.gd`; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-page-switch-cover-visual.ps1` | failing: page-switch button depressed-state assertions report `(0.0, 0.0)`. |
| `.\scripts\test-fishing-net-offer-click.ps1` | passed after fishing offer/method press-state reuse; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-fishing-web-touch-scroll.ps1` | passed after fishing offer/method press-state reuse. |
| `.\scripts\test-fishing-click-flow.ps1` | failing against the last committed baseline and after the current fishing reuse: thieving settings bottom-nav click remains on `skill`. |
| `.\scripts\test-performance-regressions.ps1` | passed after fishing offer/method press-state reuse. |
| `.\scripts\test-thieving-heist-click-flow.ps1` | passed after thieving heist press-state reuse; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after thieving heist press-state reuse. |
| `git diff --check -- scripts/main.gd scripts/ui/regen_circle.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting `scripts/ui/regen_circle.gd`. |
| `.\scripts\test-stamina-gauge-offpage-smooth.ps1` | passed after extracting `scripts/ui/regen_circle.gd`; a parallel validation warning was followed by a clean Godot process check. |
| `.\scripts\test-stamina-gauge-fail-shake.ps1` | passed after extracting `scripts/ui/regen_circle.gd`. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting `scripts/ui/regen_circle.gd`. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified header stamina gauge and firepit gauge rendering after extracting `scripts/ui/regen_circle.gd`. |
| `git diff --check -- scripts/main.gd scripts/ui/fish_circle.gd scripts/test-performance-regressions.ps1` | passed after extracting `scripts/ui/fish_circle.gd`. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting `scripts/ui/fish_circle.gd`. |
| `.\scripts\test-fishing-net-offer-click.ps1` | passed after extracting `scripts/ui/fish_circle.gd`; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-fishing-web-touch-scroll.ps1` | passed after extracting `scripts/ui/fish_circle.gd`. |
| Screenshot attempt | Full-game fishing capture and isolated FishCircle component capture both timed out under the safe wrapper; each left one owned headless Godot process that was inspected and stopped. No screenshot was accepted for this step. |
| `git diff --check -- scripts/main.gd scripts/ui/page_switch_button_face.gd scripts/ui/prism_connector_overlay.gd` | passed after extracting page-switch face and prism connector controls. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting page-switch face and prism connector controls. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting page-switch face and prism connector controls. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified header/card/module rendering after extracting page-switch face and prism connector controls. |
| `git diff --check -- scripts/main.gd scripts/ui/page_switch_chevron_icon.gd scripts/ui/module_utility_collapse_arrow.gd scripts/ui/blue_guy_health_heart_gauge.gd` | passed after extracting chevron, collapse arrow, and health gauge controls. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting chevron, collapse arrow, and health gauge controls. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting chevron, collapse arrow, and health gauge controls. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified header/card/module rendering after extracting chevron, collapse arrow, and health gauge controls. |
| `git diff --check -- scripts/main.gd scripts/test-performance-regressions.ps1 scripts/check-ui-boundary-contracts.ps1 scripts/check-activity-ui-boundary-contracts.ps1 docs/ui-runtime-boundary-map.md docs/activity-ui-boundary-map.md` | passed after deleting stale helpers. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting stale helpers. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting stale helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting stale helpers. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting stale helpers. |
| `git diff --check -- scripts/main.gd` | passed after deleting second stale-helper batch. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting second stale-helper batch. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting second stale-helper batch. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting second stale-helper batch. |
| `git diff --check -- scripts/main.gd scripts/test-performance-regressions.ps1 scripts/check-ui-boundary-contracts.ps1 docs/ui-runtime-boundary-map.md` | passed after deleting third stale-helper batch. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting third stale-helper batch. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting third stale-helper batch. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting third stale-helper batch. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting third stale-helper batch. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review of the extraction found no new issue. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified shelf/module clipping after prior UI fix. |
