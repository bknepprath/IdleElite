# Idle Slop 1 Refactor Map

Last updated: 2026-06-28

Purpose: living sidecar for the refactor. Keep this file updated when code moves, files are extracted, or session-touched files change.

Legend:
- `*` affected this session
- `(collapsed)` media/generated-heavy tree; counted by file count instead of line-by-line

## Session Notes

- Current main target: shrink `scripts/main.gd` without changing gameplay behavior.
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
| `scripts/` | 188 files / about 100,134 text lines | Game runtime script, UI drawing helpers, validation, build, and maintenance scripts. |
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
| `scripts/main.gd` * | 61,275 | Monolithic game controller: save/load, activity data, skill UI, navigation, fishing, leaderboard, chat, hub, audio, and most orchestration. Primary extraction target. |
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
| `scripts/test-performance-regressions.ps1` * | 2,922 | Static/runtime regression assertions for performance-sensitive code and UI contracts. |
| `scripts/test-save-normalization.ps1` * | 2,671 | Save/load normalization regression assertions. |
| `scripts/test-module-list-transitions.ps1` | 3,289 | Module list transition behavioral validation. |
| `scripts/test-page-switch-cover-visual.ps1` | 375 | Page-switch cover/depressed visual validation. Currently failing in this session. |
| `scripts/check-ui-boundary-contracts.ps1` | 85 | UI boundary static contracts. |
| `scripts/check-activity-ui-boundary-contracts.ps1` | 47 | Activity UI boundary contracts. |
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
| `scripts/main.gd` | modified | Shared button press-state helpers extracted for bottom nav, module utility, fishing offer, and fishing method buttons; activity-module clipping restored. |
| `scripts/ui/button_press_state.gd` | added | New extracted helper for button press-state metadata, including optional extra metadata fields. |
| `scripts/test-performance-regressions.ps1` | modified | Static assertion updated so skill detail action viewport must clip below the skill info shelf. Also contains pre-existing save/refactor assertion edits from active worktree. |
| `scripts/test-save-normalization.ps1` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `scripts/check-leaderboard-cost-safety.ps1` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.md` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.html` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/ponytail-line-reductions.md` | untracked | Pre-existing line-reduction notes. |
| `docs/refactor-file-map.md` | added | New live architecture/refactor sidecar. |

## Extraction Queue

1. Button press state
   - Current: shared metadata helper lives in `scripts/ui/button_press_state.gd`; bottom nav, module utility, fishing offer, and fishing method buttons use it.
   - Next lazy win: keep page-switch separate until its visual regression is understood.

2. Activity/skill UI ownership
   - Current: many shelf, module, card, and action rendering paths still live in `scripts/main.gd`.
   - Next lazy win: extract pure UI helper scripts only where Godot node ownership is already clear.

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
| Autoreview | no project/tool `autoreview` runner found; manual diff review of the extraction found no new issue. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified shelf/module clipping after prior UI fix. |
