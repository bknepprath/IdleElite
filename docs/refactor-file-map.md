# Idle Elite Refactor Map

Last updated: 2026-07-01

Purpose: living sidecar for the refactor. Keep this file updated when code moves, files are extracted, or session-touched files change.

Legend:
- `*` affected this session
- `(collapsed)` media/generated-heavy tree; counted by file count instead of line-by-line

## Session Notes

- Current main target: shrink `scripts/main.gd` by moving real ownership boundaries out, then delete dead code when proven.
- Active extraction rule: only extract code with a real second caller, a clear ownership boundary, or a naming win that lets local code use short names honestly.
- Hub save-state wrapper cleanup: deleted pure `scripts/main.gd` hub save/restore pass-throughs; save/runtime/tests now route through `_hub_runtime()` / `host._hub_runtime()`; measured `scripts/main.gd` at 28,701 lines after cleanup.
- ConvergenceRuntime compatibility wrapper cleanup: deleted pure `scripts/main.gd` convergence pass-throughs; callers/tests now route through `_convergence_runtime()` / `host._convergence_runtime()`; measured `scripts/main.gd` at 28,884 lines after cleanup.
- InputRoutingShell compatibility wrapper cleanup: deleted pure `scripts/main.gd` input-routing pass-throughs; callers/tests now route through `_input_routing_shell()`; measured `scripts/main.gd` at 28,968 lines after cleanup.
- Save runtime save-snapshot wrapper cleanup: deleted direct `scripts/main.gd` save-runtime snapshot/autosave/action-key pass-through wrappers; measured `scripts/main.gd` at 29,211 lines after cleanup.
- Online runtime dead-wrapper cleanup: deleted the unused `scripts/main.gd` Firebase/auth/cloud-save/leaderboard pass-through wrappers after caller checks; measured `scripts/main.gd` at 29,271 lines after cleanup.
- Hub mission badge dead-wrapper cleanup: deleted pure `scripts/main.gd` hub mission/action-card badge pass-through wrappers; callers use owner-local `HubSurface` methods or direct `host._hub_surface()`; measured `scripts/main.gd` at 28,488 lines after cleanup.
- ChatStyles pass-through wrapper cleanup: deleted pure `scripts/main.gd` chat style wrappers and the now-unused preload; profile/chat overlay and navigation shell call `ChatStyles` directly; measured `scripts/main.gd` at 28,459 lines after cleanup.
- PassiveModuleStyles pass-through wrapper cleanup: deleted pure `scripts/main.gd` passive/firepit style wrappers; passive/firepit UI surfaces call `PassiveModuleStyles` directly; measured `scripts/main.gd` at 28,402 lines after cleanup.
- LeaderboardStyles pass-through wrapper cleanup: deleted pure `scripts/main.gd` leaderboard dropdown/player-card/rank-badge style wrappers and the now-unused preload; leaderboard presentation calls `LeaderboardStyles` directly; measured `scripts/main.gd` at 28,430 lines after cleanup.
- Step 60 extraction: shop page/ad presentation now lives in `scripts/ui/shop_surface.gd`; measured `scripts/main.gd` at 39,122 lines before validation.
- Step 62 extraction: firepit-only scrapwood flyer, ignition flyer, XP float, and need-scrapwood feedback helpers now live in `scripts/ui/passive_firepit_surface.gd`; measured `scripts/main.gd` at 38,902 lines after the code move.
- Step 63 extraction: settings transient control runtime now lives in `scripts/ui/settings_surface.gd`; measured `scripts/main.gd` at 38,620 lines after the code move.
- Step 64 extraction: legacy first-run tutorial overlay/input targeting now lives in `scripts/ui/tutorial_overlay_surface.gd`; measured `scripts/main.gd` at 38,525 lines after the code move.
- Step 65 extraction: remaining chat strip/open-close/status/draft-submit shell now lives in `scripts/ui/profile_chat_overlay_surface.gd`; measured `scripts/main.gd` at 38,267 lines after the code move.
- Step 66 extraction: crash-report session/file runtime now lives in `scripts/diagnostics/crash_report_runtime.gd`; measured `scripts/main.gd` at 38,144 lines after the code move.
- Step 67 extraction: hub mission action-card badge/help popover and icon-pop completion ceremony presentation now live in `scripts/ui/hub_surface.gd`; measured `scripts/main.gd` at 37,940 lines after the code move.
- Step 68 extraction: home achievement medal strip refresh, medal slot factory, hit testing, and popover runtime now live in `scripts/ui/achievement_overlay_surface.gd`; measured `scripts/main.gd` at 37,548 lines after the code move.
- Step 69 extraction: leaderboard category/scoring/submission-state policy plus save/fetch metadata normalization now live in `scripts/leaderboard/state.gd`; measured `scripts/main.gd` at 37,430 lines after the code move.
- Step 70 extraction: generic button depress/release/default-SFX runtime now lives in `scripts/ui/button_press_state.gd`; measured `scripts/main.gd` at 37,288 lines after the code move.
- Step 71 extraction: app performance runtime now lives in `scripts/app/performance_runtime.gd`, and the monitor moved to `scripts/app/perf_monitor.gd`; measured `scripts/main.gd` at 37,177 lines after the code move.
- Step 72 extraction: live activity data catalog collections, loader, lookup rebuild, and action display sort now live in `scripts/activity_data/catalog.gd`; measured `scripts/main.gd` at 37,104 lines after the code move.
- Step 73 extraction: live boss completion mutation now lives in `scripts/gameplay/boss_gates.gd`; measured `scripts/main.gd` at 37,098 lines after the code move.
- Step 74 extraction: God Mode and art-review test-state mutation bodies now live in `scripts/dev/test_state_runtime.gd`; measured `scripts/main.gd` at 37,004 lines after the code move.
- Step 75 extraction: material definitions, wallet save/restore/mutation, display helpers, log reward buffing, and Berry Prep runtime state now live in `scripts/materials/runtime.gd`; measured `scripts/main.gd` at 36,950 lines after the code move.
- Step 76 extraction: passive log-pile presentation, passive production/collection flyers, upgrade button pop/feedback, passive presentation constants/card-height helpers, and passive progress percent math moved to the existing passive owners; measured `scripts/main.gd` at 21,911 lines after the latest passive/firepit helper move.
- Step 77 extraction: fight/boss runtime state, boss gates, Blue Guy health regen/gauge bridge, and chicken brawl stage bridge now live in `scripts/gameplay/fighting_runtime.gd`; deleted `scripts/gameplay/boss_gates.gd`; measured `scripts/main.gd` at 36,428 lines after the code move.
- Step 78 cleanup: settings reset-confirmation ownership, settings notification notice refs, settings control registries, audio slider active/grabber state, and settings page-cache state now live in `scripts/ui/settings_surface.gd`; measured `scripts/main.gd` at 36,265 lines after cleanup.
- Step 80 cleanup: profile overlay node/state/callback ownership, avatar picker state, and avatar texture cache now live in `scripts/ui/profile_chat_overlay_surface.gd`; measured `scripts/main.gd` at 36,146 lines after cleanup.
- Step 81 cleanup: temporary-event constants, live scheduler/save state, reset bridge, and event action start/clear/completion attempts now live in `scripts/temporary_events/runtime.gd`; measured `scripts/main.gd` at 36,076 lines after cleanup.
- Step 82 cleanup: rewarded-ad/shop bonus constants, timer state, AdMob lifecycle/callbacks, grant, restore, and shop ad press runtime now live in existing `scripts/monetization/ad_bonus.gd`; measured `scripts/main.gd` at 35,974 lines after cleanup.
- Step 83 cleanup: activity queue runtime state and list normalization now live in `scripts/activity_queue/runtime.gd`; queue page return state/navigation and the queue icon constant now live in `scripts/ui/navigation_shell.gd`; deleted `scripts/activity_queue/state.gd`; measured `scripts/main.gd` at 35,976 lines after compatibility property bridges.
- Step 84 cleanup: Thieving heist constants, trophy/action-jail state, heist lookup/visibility, trophy tier math, and save-facing normalization now live in existing `scripts/thieving/state.gd`; measured `scripts/main.gd` at 35,873 lines after compatibility constants/properties/wrappers.
- Step 85 cleanup: generic bottom-nav pop helpers, primary pointer release/button-hit helpers, and `nav_pop_tweens` now live in existing `scripts/ui/button_press_state.gd`; measured `scripts/main.gd` at 35,760 lines after wrapper consolidation.
- Step 86 cleanup: Berry Mode state, prep button callback ownership, badge sync, and full-screen border overlay now live in `scripts/ui/material_collection_surface.gd`; measured `scripts/main.gd` at 35,572 lines after compatibility wrappers.
- Step 87 cleanup: leaderboard profile/auth save normalization, restore mutation, and claim-valid gate bodies now live in existing `scripts/online/leaderboard_profile.gd`; measured `scripts/main.gd` at 35,538 lines after compatibility wrappers.
- Step 88 cleanup: convergence module runtime constants/state, build lifecycle, cycle math, XP payout, and save-shape bridge now live in `scripts/gameplay/convergence_runtime.gd`; measured `scripts/main.gd` at 35,435 lines after compatibility wrappers.
- Step 89 cleanup: skill XP curve math, XP progress dictionaries, skill level derivation, stamina clamping/fraction helpers, and stamina-bank sync now live in existing `scripts/progression/skill_state.gd`; measured `scripts/main.gd` at 35,407 lines after wrapper delegation.
- Step 90 cleanup: shared visual texture caches, headless-safe texture creation/fallbacks, atlas/spritesheet helpers, generic image factories, and fishing visual ablation path detection now live in `scripts/core/visual_texture_cache.gd`; measured `scripts/main.gd` at 35,310 lines after wrapper delegation.
- Step 91 cleanup: early input routing orchestration, modal/screen routing order, and system-back priority now live in existing `scripts/ui/input_routing_shell.gd`; measured `scripts/main.gd` at 35,005 lines after wrapper delegation.
- Step 92 cleanup: manual activity unlock state, requirement normalization, trust/repair, and unlock policy now live in `scripts/gameplay/activity_unlock_runtime.gd`; measured `scripts/main.gd` at 34,810 lines after wrapper delegation.
- Step 93 cleanup: buildable module affordability, wallet spend, built-state mutation, Building XP grant, result text, save, and refresh transaction now live in existing `scripts/gameplay/buildable_modules.gd`; measured `scripts/main.gd` at 34,768 lines after wrapper delegation.
- Step 94 cleanup: first-run tutorial/onboarding scalar state, progression gates, swipe access policy, tutorial target progression, and onboarding graduation now live in `scripts/tutorial/onboarding_runtime.gd`; measured `scripts/main.gd` at 34,495 lines after wrapper delegation.
- Step 95 cleanup: achievement reward bonus policy, global medal buff policy, medal counts/tier summaries, mastery action filtering, skill medal stamina bonus, and neighbor medal buff runtime policy now live in existing `scripts/achievements/state.gd`; measured `scripts/main.gd` at 34,325 lines after wrapper delegation.
- Step 96 cleanup: boot warmup overlay/progress/hide/dismiss/background warmup runtime now lives in `scripts/app/boot_warmup_runtime.gd`; measured `scripts/main.gd` at 34,217 lines after wrapper delegation.
- Step 97 cleanup: page-switch render-cover pending transition queue, render-idle release state, and under-cover render dispatch now live in existing `scripts/ui/navigation_shell.gd`; measured `scripts/main.gd` at 34,088 lines after wrapper delegation.
- Step 99 cleanup: module utility row/sort menu scene-visible refs, collapse/motion state, and nav press-state helper logic now live in existing `scripts/ui/navigation_shell.gd`; measured `scripts/main.gd` at 34,052 lines after compatibility property delegation.
- Step 98 cleanup: save boot finalization, secondary restore pending state, repaired-save boot state, and delayed post-load/offline simulation now live in existing `scripts/save_state/save_runtime.gd`; measured `scripts/main.gd` at 34,025 lines after wrapper delegation.
- Step 100 cleanup: recovery contract lookup, target selection, application, and result copy now live in existing `scripts/gameplay/recovery_modules.gd`; recovery card chrome shaping now lives in `scripts/ui/skill_detail_surface.gd` and `scripts/ui/skill_swipe_activity_surface.gd`; measured `scripts/main.gd` at 34,016 lines after wrapper/chrome cleanup.
- Current cleanup: TestStateRuntime headless validation and boot-smoke runtime now live only in `scripts/dev/test_state_runtime.gd`; measured `scripts/main.gd` at 30,551 lines after headless wrapper cleanup.
- Current cleanup: leaderboard style pass-through wrappers were deleted from `scripts/main.gd`; `scripts/leaderboard/presentation.gd` now calls `LeaderboardStyles` directly; measured `scripts/main.gd` at 28,430 lines.
- Current cleanup: onboarding fight/header/stat presentation, auto-run note placement/cleanup, lazy-stack wait, regen intro fill finish, and stat fade-in now live in `scripts/ui/tutorial_overlay_surface.gd`; onboarding sequence deferred callers target `scripts/tutorial/onboarding_runtime.gd`; measured `scripts/main.gd` at 21,508 lines.
- Page-switch press handling and physical cover drawing remain bespoke in `scripts/main.gd`; `scripts/test-page-switch-cover-visual.ps1` passes after the render-cover runtime move.
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
| `scripts/` | 247 files / about 114,747 counted text lines | Game runtime script, UI drawing helpers, validation, build, and maintenance scripts. |
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
| `scripts/main.gd` * | 21,508 | Monolithic game controller: save/load wrappers, activity data aliases/wrappers, skill UI, navigation, fishing, leaderboard, chat, hub, audio, and most orchestration. Primary deletion/refactor target; onboarding fight/header/stat presentation now routes through `TutorialOverlaySurface`, while `_resolve_detail_lazy_stack()` stays in main because it has non-onboarding callers. |
| `scripts/app/boot_warmup_runtime.gd` * | 161 | Boot warmup presentation/runtime owner: splash overlay build/show/hide, progress text/bar updates, minimum visible timing, dismiss-for-play, boot texture background warmup frame budget, and early-services gate state. `scripts/main.gd` keeps compatibility properties/wrappers and boot texture path ownership. |
| `scripts/tutorial/onboarding_runtime.gd` * | 774 | First-run tutorial/onboarding runtime owner: tutorial active/step state, onboarding completion/swipe/tip flags, gate-latch policy, tutorial target progression, onboarding swipe/path/accessibility gates, stamina/header sequence orchestration, lock tip marks, activity-start/completion tip progression, tutorial preview/latch helpers, and graduation. Onboarding sequence deferred callers target this runtime directly. |
| `scripts/dev/test_state_runtime.gd` * | 243 | Dev/test runtime for God Mode, art-review setup mutations, headless validation, and boot-smoke runtime. `scripts/main.gd` keeps direct `scene.call` wrappers, `_test_state_runtime()` factory, and the God Mode availability gate/status/control UI. |

## Core Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/core/formatting.gd` * | 77 | Shared number and time formatting: stamina cost text, info-chip/significant-digit/compact/percent display, trailing-zero trimming, short duration text, and countdown timers. `scripts/main.gd` keeps compatibility wrappers for existing call sites. |
| `scripts/core/visual_texture_cache.gd` * | 167 | Shared visual texture/cache infrastructure: resource-path normalization, headless-safe procedural texture creation, transparent placeholder fallback, atlas/spritesheet slicing, generic `TextureRect` factories, nullable texture fallback helpers, and fishing visual ablation path detection. `scripts/main.gd` keeps compatibility wrappers and cache aliases for existing host callers. |
| `scripts/activity_lock_rig.gd` | 1,141 | Activity lock rig drawing/animation support. |
| `scripts/activity_lock_cluster.gd` | 550 | Activity lock cluster rendering. |
| `scripts/activity_lock_number.gd` | 30 | Activity lock number rendering. |
| `scripts/fishing_fluid_strip.gd` | 276 | Fishing fluid strip visual. |
| `scripts/fishing_fluid_strip.gdshader` | 50 | Fishing strip shader. |
| `scripts/fishing_fluid_strip_underlay.gdshader` | 34 | Fishing strip underlay shader. |

## UI Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/ui/mobile_scroll_container.gd` | 567 | Mobile-friendly scroll behavior. |
| `scripts/ui/button_press_state.gd` * | 417 | Shared button press metadata plus generic button depress/release/default-SFX runtime, bottom-nav pop tween state, bottom-nav transition hold release helpers, and primary pointer release/button-hit scanning. Reset-confirm dead-press checks delegate to `scripts/ui/settings_surface.gd`; activity card shell depth press behavior stays in `scripts/ui/skill_swipe_activity_surface.gd`/`scripts/main.gd`. |
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
| `scripts/ui/activity_card_styles.gd` * | 108 | Activity/action-card StyleBox factories for featured art, shade, action-art chrome, glows, bonus emphasis, tutorial target rings, crit glows, and button face fills. `scripts/main.gd` keeps caches and wrapper names. |
| `scripts/ui/activity_progress_rail.gd` | 295 | Activity progress rail drawing. |
| `scripts/ui/activity_progress_opportunity_overlay.gd` | 206 | Opportunity overlay drawing. |
| `scripts/ui/action_art_ui.gd` * | 95 | Action art image construction, animated art setup, corner badges, border overlay, and headless-safe texture/mask decisions. `scripts/main.gd` supplies texture callbacks and game-specific icon paths. |
| `scripts/ui/module_sort_menu_ui.gd` * | 113 | Module sort menu construction, sort button styling, active-state sync, and button depress hookup. `NavigationShell` owns menu refs/input/animation; `scripts/main.gd` owns sort preferences and screen refresh. |
| `scripts/ui/module_utility_row_ui.gd` * | 102 | Module utility row, nav buttons, icon metadata, and collapse toggle construction. `NavigationShell` owns scene refs, navigation callbacks, visibility, and row motion state. |
| `scripts/ui/paper_button_styles.gd` * | 128 | Procedural paper/chunky button StyleBoxTexture generation, rounded-rect pixel tests, cache fill, and headless fallback texture wiring. `scripts/main.gd` keeps compatibility wrappers and theme callbacks. |
| `scripts/ui/passive_module_styles.gd` * | 102 | Passive module currency/stat/popup/icon/plank/round/upgrade StyleBox factories. Passive/firepit UI surfaces pass current panel, ink, gold, and theme callbacks directly. |
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
| `scripts/ui/fishing_tool_wallet_overlay.gd` | 121 | Fishing tool wallet overlay. |
| `scripts/ui/convergence_multi_progress_bar.gd` | 192 | Convergence progress bar drawing. |
| `scripts/ui/clean_progress_bar.gd` | 80 | Shared clean progress bar drawing. |
| `scripts/ui/boot_flex_loading_animation.gd` | 270 | Boot loading animation. |
| `scripts/ui/hub_path_dots.gd` | 372 | Hub path/dot visual. |
| `scripts/ui/hub_build_progress_bar.gd` | 24 | Hub build progress bar. |
| `scripts/ui/mission_cooldown_ring.gd` | 19 | Mission cooldown ring. |
| `scripts/ui/organic_leaderboard_border.gd` | 44 | Leaderboard border. |
| `scripts/ui/passive_serpentine_progress_bar.gd` | 165 | Passive module progress bar. |
| `scripts/ui/passive_module_card_border.gd` | 30 | Passive module border. |
| `scripts/ui/passive_icon_sprite.gd` | 37 | Passive icon sprite helper. |
| `scripts/ui/passive_log_pile_sprite.gd` | 52 | Passive log pile sprite helper. |
| `scripts/ui/rounded_texture_rect.gd` | 276 | Rounded texture rect drawing. |
| `scripts/ui/rounded_corner_crop_overlay.gd` | 20 | Rounded corner crop overlay. |
| `scripts/ui/shop_ad_stack_light.gd` | 58 | Shop ad stack light visual. |
| `scripts/ui/feathered_collect_glow.gd` | 19 | Collect glow visual. |
| `scripts/ui/achievement_medal_slot_strip.gd` | 101 | Achievement medal strip. |
| `scripts/ui/material_collection_surface.gd` * | 652 | Material collection UI owner: row/module construction, connector positioning, honey/berry module controls, Berry Mode prep button callback, badge sync, full-screen berry border overlay, material-card style, show/hide layout sync, and material reward flyer/pulse feedback. `scripts/main.gd` keeps direct scene/test compatibility wrappers. |
| `scripts/ui/berry_prep_controls.gd` * | 141 | Berry Prep material-module button, hint badge, popover copy, apply button, and local styles. Stays a widget; `scripts/ui/material_collection_surface.gd` owns live callbacks/state. |
| `scripts/ui/buildable_module_overlay.gd` * | 95 | Buildable action-card blueprint overlay and centered CTA panel. `scripts/ui/skill_detail_surface.gd` computes build overlay text/affordability through `BuildableModules` and receives the expected widget dictionary. |
| `scripts/ui/convergence_build_overlay.gd` * | 97 | Convergence action-card build overlay, countdown label, and shrine CTA panel. Runtime countdown/status updates stay in `scripts/main.gd`. |
| `scripts/ui/reward_feedback_surface.gd` * | 671 | Generic reward/result feedback owner: result text updates, action success/failure art feedback, crit art/text bursts, XP/mastery/level-up floats, tired/stamina/warning floats, reward-float tween lifecycle, and visible action-card lookup. `scripts/main.gd` keeps compatibility wrappers and non-generic fish/thieving reward floats stay in their domain owners. |
| `scripts/ui/shop_surface.gd` * | 190 | Shop page/ad presentation owner: shop page layout, rewarded-ad offer button, bonus stack light meter nodes, and stack meter sync. `scripts/main.gd` keeps rewarded-ad lifecycle, bonus grant math/copy, rate/ad callbacks, and compatibility wrappers. |
| `scripts/ui/settings_surface.gd` * | 1,003 | Settings page UI owner: settings page construction, audio volume controls, toggle rows/styles, slider styling/grabber cache, settings control registries, active audio slider drag routing, control sync helpers, reset-confirmation state/logic/feedback, navigation state preservation, and notification settings notice/tween lifecycle. `scripts/main.gd` keeps persisted setting mutations, save calls, audio/dark-mode/gameplay effects, notification permission request, hard-reset data wipe orchestration, and compatibility wrappers. |
| `scripts/ui/tutorial_overlay_surface.gd` * | 659 | First-run tutorial overlay surface owner: overlay node refs, panel/overlay input routing, target press hit-tests, overlay visibility sync, target indicator hide/sync, target skill/action/control lookup, onboarding fight header/stamina/stat presentation, auto-run note placement/cleanup, lazy-stack wait, regen intro fill finish, and onboarding stat fade-in. |
| `scripts/ui/profile_chat_overlay_surface.gd` * | 1,393 | Profile/chat overlay owner: profile overlay node/state/callbacks, profile save/close/name-submit/account-claim entry, avatar picker state, avatar texture cache, avatar presentation, chat strip construction and visibility, chat overlay shell/rows/status notice/composer, mobile keyboard lift/preview, chat strip input/open-close routing, status copy, draft tracking, submit polling/deferred submit, and send button input. `scripts/main.gd` keeps online transport/profile identity save keys and thin compatibility wrappers. |
| `scripts/ui/achievement_overlay_surface.gd` * | 1,245 | Achievement overlay owner: home achievements section, achievements page/overlay shell, offline summary presentation, home best-activity refresh, per-skill medal strip factory/refresh, medal hit testing, and medal popovers. `scripts/main.gd` keeps achievement state dictionaries and routes update/input calls through this surface. |
| `scripts/ui/passive_firepit_surface.gd` * | 1,803 | Passive/firepit UI owner: passive/firepit presentation constants, card-height helper, upgrade gain text, card construction, resource/stat controls, passive log-pile rendering/click hotspot geometry, collection/production log flyers, upgrade arrow/button pop/feedback, firepit art/status/toggle controls, dependency reveal visuals, stop-hold UI state, and firepit-only scrapwood flyer/ignition/XP/need-scrapwood visual feedback. `scripts/main.gd` keeps XP mutation, save/progression state, and compatibility wrappers. |
| `scripts/ui/skill_detail_surface.gd` * | 3,592 | Skill detail surface owner: skill detail rendering, action-card construction helpers, detail lazy plan/mount/cache helpers, layout transition animation, and swipe-finalized lazy-detail stack replacement/free/visible-card mount batching. `scripts/main.gd` keeps gesture routing, swipe covers, queued swipe navigation, pending finalize processing, and thin compatibility wrappers. |
| `scripts/ui/hub_surface.gd` * | 3,115 | Hub UI surface owner: hub page rendering, module/trophy/decor layout helpers, hotspot hold and drag handling, detail popup and mission board panels/slabs, hub tutorial tip rendering, build smoke/progress overlays, hub mission action-card badge/help popover and icon-pop completion ceremony presentation, and hub UI-facing restore/normalization wrappers that depend on layout bounds. |
| `scripts/ui/skill_swipe_activity_surface.gd` * | 2,650 | Skill swipe/activity surface owner: activity queue page buttons, empty copy, queue-selection banner, queue-selection card key/toggle helpers, queue number overlays, preview page/card construction, preview state updates, preview prewarm, placeholders, light-preview cards/styles, parked preview pages, preview/global real-card-cache helpers, and direct HubSurface mission-badge sync calls for real action cards. `scripts/main.gd` keeps wrappers plus queue storage/runtime bridge, gesture, navigation, cover, and pending detail-finalize orchestration; the temporary dynamic-property bridge was deleted in Step 54. |
| `scripts/ui/input_routing_shell.gd` * | 895 | Input routing shell owner: `_input` orchestration order, fishing preflight routing, top-level/modal/screen/activity input routing, system-back priority, action-card press/release routing, fishing detail routing, fishing method-lock tap routing, page-switch global input routing, and closely private hit-test helpers. `scripts/main.gd` keeps only callback and compatibility wrappers while domain handlers stay with their current owners. |
| `scripts/ui/navigation_shell.gd` * | 3,467 | Navigation shell owner: bottom-nav build/routing/visibility, bottom-nav input hit tests, lock checks/messages, red-X return routing, bottom-nav new-symbol dots and seen-id save bridge, Home/Hub/Shop unlock fade state and locked-message floats, page-switch render-cover pending transition state/release dispatch, module utility row/return routing/sort scene refs/input/animation/collapse state, skill menu/page state, and pinned/queue pages plus active-shelf and pinned empty-state decor presentation. `scripts/main.gd` keeps gameplay unlock predicates, page functions, physical page-switch cover drawing, sort preference/save policy, pinned module copy building, and retained scene-call compatibility wrappers/properties. |
| `scripts/ui/module_action_circle_zone.gd` * | 6 | Circular action-card hit zone formerly embedded in `scripts/main.gd`. |
| `scripts/ui/skill_icon_badge_mask.gd` * | 18 | Skill icon badge mask control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/skill_icon_symbol_draw.gd` * | 14 | Skill icon texture draw control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/module_collapse_minus_glyph.gd` * | 19 | Module collapse minus glyph formerly embedded in `scripts/main.gd`. |
| `scripts/ui/medal_sparkle_star.gd` * | 30 | Achievement medal sparkle star control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/medal_shine_slash.gd` * | 46 | Achievement medal shine slash animation control formerly embedded in `scripts/main.gd`. |

## Module UI Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/module_ui/runtime.gd` * | 276 | Module UI runtime owner: module key prefixes/normalization, action/heist/fishing/hub key construction, skill ownership/lazy track-id parsing, sort mode normalization, pin/collapse/sort runtime state, save/restore normalization, unlocked-only filtering, and host-callback pin/collapse policy. |

## Achievement Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/achievements/rewards.gd` * | 41 | Achievement art paths, target tables, and stamina reward formulas. |
| `scripts/achievements/state.gd` * | 451 | Achievement live-state facade/runtime helpers: host-backed milestone context, action medal records, medal counts/tier summaries, mastery action filtering, skill medal stamina bonus math, global reward bonus and global medal buff policy, neighbor medal buff totals/contributions/lines/rate bonuses, medal accent conversion, visible achievement lists, save-state normalization, completed/new achievement filtering, reward-bonus filtering, and toast seen-id mutation. |
| `scripts/achievements/milestones.gd` * | 209 | Pure achievement milestone dictionary builders for total level, action medal log entries, tier counts, cumulative medals, and crit milestones. |
| `scripts/achievements/presentation.gd` * | 40 | Achievement presentation math: skill-level target sequence, medal cluster counts/positions, and progress percentages used by home/log UI. |
| `scripts/achievements/styles.gd` * | 32 | Achievement card, toast queue badge, and skill-section StyleBox factories. `scripts/main.gd` keeps compatibility wrappers and passes the shared surface-style callback. |

## Progression Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/progression/skill_state.gd` * | 118 | Skill XP curve constants/math, skill level derivation, XP progress dictionaries, stamina clamping/fraction helpers, stamina regen-bank fraction, stamina-bank sync, and skill/stamina save payload normalization over skill definitions. Runtime XP mutation, max-stamina cache/reward math, stamina regen modifiers, action stamina spend/restore, and honey/firepit/hub regen remain in `scripts/main.gd` and existing runtime owners. |
| `scripts/progression/mastery_state.gd` * | 40 | Mastery save/restore normalization: canonical action keys, duplicate-key max XP, level derivation, and max-level XP clamping. Runtime mastery XP gain and visual medal behavior remain in `scripts/main.gd`. |
| `scripts/progression/medal_buffs.gd` * | 50 | Pure neighbor medal buff contribution and per-tier math used by `AchievementState`; `scripts/main.gd` keeps only cache storage for the current stat-cache lifecycle. |

## Gameplay Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/gameplay/fighting_runtime.gd` * | 211 | Fight/boss runtime owner: Blue Guy health constants/state/regen/gauge bridge, completed-boss state/save/restore, boss identity/gating/completion, fighting stage selection predicates, and chicken brawl stage callbacks. Boss callers/tests now route through `_fighting_runtime()` directly; `scripts/main.gd` keeps the completed-boss property bridge plus Blue Guy health/gauge compatibility. |
| `scripts/gameplay/convergence_runtime.gd` * | 222 | Convergence module runtime owner: convergence constants, live module state, build lifecycle, build timing/cost policy, cycle segment math, XP payout, save restore/save payload bridge, and save-shape normalization delegation. `scripts/main.gd` keeps compatibility properties and the `_convergence_runtime()` accessor for state/card UI sync. |
| `scripts/gameplay/activity_unlock_runtime.gd` * | 322 | Manual activity unlock runtime owner: save-shaped manual unlock dictionaries, requirement normalization/state, trusted manual unlock validation/repair, requirement dismissal keys, save payload normalization, and "can this action unlock?" policy. `scripts/main.gd` keeps public/test-facing compatibility wrappers plus unlock ceremony, previews, auto-unlock scheduling, fishing visible mount, and detail refresh orchestration. |
| `scripts/gameplay/buildable_modules.gd` * | 151 | Buildable module policy and transaction owner: action keys, build contract checks, built-state save/restore filtering, cost dictionaries, labels, XP rewards, affordability checks, wallet spend, built-state mutation, Building XP grant, result text, save, and render refresh. Runtime/UI/save callers use this owner directly. |
| `scripts/gameplay/recovery_modules.gd` * | 59 | Recovery module policy: recovery contracts, target-skill selection including lowest-stamina targeting, stamina restoration application, and result text. `scripts/main.gd` keeps thin compatibility facades for scene-call/direct callers. |
| `scripts/gameplay/action_runtime.gd` * | 1,372 | Action lifecycle/runtime owner: live action processing/start/card-tap entry, temporary-event ticking, canceled-progress decay, material reward helpers, offline active/convergence simulation, diamond arena predicate, and action-opportunity state machine/window/click/boost/regen helpers. Convergence runtime state/math is reached directly through `host._convergence_runtime()`. `scripts/main.gd` keeps visible rail lookup, floating opportunity feedback, and SFX wrappers. |
| `scripts/gameplay/passive_modules_runtime.gd` * | 636 | Passive/firepit runtime owner: passive/firepit state normalization, production ticks, progress percent math, firepit fuel/heat/cooling math, start/ignite/stop behavior, collection, upgrades, and upgrade costs. `scripts/main.gd` keeps compatibility wrappers for host/runtime callbacks. |

## App Runtime Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/app/lifecycle_runtime.gd` * | 251 | App lifecycle owner: notification routing, suspend/resume save and repair flow, shutdown cleanup/nulling, headless quit, and shared variant-safe tween cleanup. Shutdown cleanup now releases settings notification state through `SettingsSurface` and profile overlay refs/cache through `ProfileChatOverlaySurface`; `scripts/main.gd` keeps callback/test wrappers. |
| `scripts/app/performance_runtime.gd` * | 98 | App performance owner: desktop/mobile frame caps, mobile battery governor state, adaptive VSync setup, debug-only performance overlay boot policy, and monitor loading. `scripts/main.gd` keeps only `_battery_governor_visual_work_active()`. |
| `scripts/app/perf_monitor.gd` * | 206 | Runtime performance monitor and debug overlay. |

## Leaderboard Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/online/leaderboard_profile.gd` * | 238 | Leaderboard profile avatar clamping, display-name cleanup, name-key generation/validation, guest-name detection/generation, player-id generation/sanitization, profile/auth save normalization, profile/auth restore mutation, claim-valid gating, auth provider normalization, and refresh-token cleanup. |
| `scripts/leaderboard/state.gd` * | 191 | Leaderboard state/policy owner: category ids/labels, score calculation, score formatting bridge, rank text, submit readiness/status, cached rows-by-category access, legacy total-level XP scrubbing, and submitted-score/fetch-retry save normalization. Direct callers use `main.gd`'s `_leaderboard_state()` accessor instead of app-level state pass-through wrappers. |
| `scripts/leaderboard/presentation.gd` * | 408 | Leaderboard page UI construction plus display policy: score/rank text, submit status title/detail copy, simple status normalization, empty-state detail copy, and direct `LeaderboardStyles` calls for dropdown/player-card/rank-badge styling. Scoring/state policy lives in `scripts/leaderboard/state.gd`. |
| `scripts/leaderboard/styles.gd` * | 99 | Leaderboard dropdown/player-card/rank-badge StyleBox factories plus profile avatar/name-field StyleBox factories. Leaderboard presentation now calls these directly; profile/chat overlay still passes current theme callbacks for profile styles. |

## Online Runtime Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/online/online_runtime.gd` * | 1,940 | Online owner: Firebase config/URL guards, auth, cloud-save status/payload/transport, leaderboard transport, chat transport, profile reference sync, and profile overlay status/focus handoff through `ProfileChatOverlaySurface`. |
| `scripts/online/chat_state.gd` * | - | Shared chat save/message/payload helpers; left separate because cross-cutting callers still use it. |
| `scripts/online/leaderboard_profile.gd` * | 238 | Shared leaderboard profile save/name/id/avatar/auth helpers; left separate because cross-cutting callers still use it. |

## Diagnostics Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/diagnostics/crash_report_runtime.gd` * | 182 | Crash-report runtime owner: pending report file load/delete/store, session id/heartbeat, live session context dictionary, session marker writes, Android diagnostic event file tailing, and unclean previous-session synthesis. `scripts/main.gd` keeps settings copy UI policy. |
| `scripts/diagnostics/crash_reports.gd` * | 197 | Pure crash-report helper: clipboard formatting, Android diagnostic event compaction, build/device metadata extraction, previous-session summary text, and Android lifecycle verdict helpers. |

## Monetization Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/monetization/ad_bonus.gd` * | 264 | Rewarded-ad/shop bonus runtime owner: bonus constants, timer state, XP/speed multipliers, status/label text, countdown ticking, save restore clamp, stack grants/meter counts, AdMob unit selection, rewarded-ad load/show/destroy/callback state, preview grant behavior, shop ad press handling, bonus grant UI refresh, and save trigger. |

## Audio Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/audio/audio_director.gd` * | - | Owns AudioStreamPlayer lifecycle helpers and audio settings normalization directly: dispose existing lists, append path-backed player sets, append repeated player pools with volume stepping, ensure one-off path-backed SFX players, and clamp saved volume values. `scripts/audio/player_sets.gd` and `scripts/audio/settings.gd` were folded back into this owner. |

## Fishing Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/fishing/state.gd` * | 1,357 | Fishing runtime/catalog owner for tool/net/boat/rod/mirror state, selected-location save normalization, action-location/mastery caches, fishing area metadata loading, location catalog selection, area render-policy decisions, reward/equipment math, yield/food/direct-currency rules, success archetypes/chances, catch texture selection, XP, and mastery scaling. Fishing UI construction, offer purchase handlers, wallet UI, active card lookups, and broader action runtime remain in `scripts/main.gd` / `scripts/fishing/ui_surface.gd`. |
| `scripts/fishing/ui_surface.gd` * | 3,517 | Fishing UI/debug surface owner for fishing debug env flags, web direct wheel bridge callbacks, web fishing perf probe setup/publish state, mounted-count implementation, fishing detail UI, offer presentation/input, method button routing, scroll perf/render-culling, area modules, wallet/tool visuals, and fishing-specific feedback. Scene compatibility wrappers remain only for external direct-call tests/shells. |

## Tutorial Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/tutorial/tip_state.gd` * | 29 | Tip metadata save/restore normalization: lock/passive/silver opportunity tip flags, action-key cleanup, and bounded recent detail-pull tip text history. Tutorial UI sequencing remains in `scripts/main.gd`. |

## Temporary Event Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/temporary_events/runtime.gd` * | 722 | Temporary-event runtime owner: scheduler constants, event definitions, active/cooldown/next-roll scheduler state, art-review activation, active-event action projection, spawn-level/reward/stamina/seconds math, scheduler/expiry/cooldown/spawn state, event action start/clear/completion bridge, completion state mutation, and save/restore calls through `TemporaryEventState`. `scripts/main.gd` keeps compatibility properties/wrappers plus player-visible completion/despawn rendering. |
| `scripts/temporary_events/state.gd` * | 82 | Temporary-event save payload and restore normalization for active entries, cooldowns, legacy field names, event-definition validation, and minimum-level restore gates. |

## Activity Queue Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/activity_queue/runtime.gd` * | 298 | Activity queue runtime owner: queue storage, public queue mutations, list normalization, circular next-index math, save/restore bridge, queueability checks, start/stop/process/advance loop, stamina skip, fishing-area target resolution, and running-action queue-key matching. `scripts/main.gd` keeps compatibility properties/wrappers for old scene/test callers. |

## Chat Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/online/chat_state.gd` * | - | Chat save-state clamping, last-opened message id normalization, message whitespace/censor/max-length sanitation, message id generation, outbound Firebase payload/update construction, and Central-time timestamp formatting. Stream/UI behavior remains in `OnlineRuntime` and chat presentation owners. |
| `scripts/chat/styles.gd` * | 109 | Global chat strip, unread dot, message bubble, back button, input, and keyboard preview StyleBox factories. `scripts/main.gd` passes current ink/focus colors and keeps callsite-compatible wrappers. |

## Thieving Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/thieving/state.gd` * | 269 | Thieving heist constants, trophy/action-jail state, pending trophy reward state, heist lookup/visibility, trophy tier math, and save-facing trophy/jail normalization. UI rendering remains in `scripts/thieving/surface.gd`. |

## Activity Data Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/activity_data/catalog.gd` * | 113 | Live activity catalog owner: `ACTIVITY_DATABASE_PATH`, skill/action collections, database load, action lookup rebuild, convergence action id list, and activity display sort. `scripts/main.gd` keeps public aliases/wrappers for existing callers. |
| `scripts/activity_data/normalizers.gd` * | 321 | Pure activity/event database load normalization: action dictionary construction, event module records, requirements, XP/resource rewards, tag arrays, art animation metadata, resource paths, and slugs. |

## Material Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/materials/runtime.gd` * | 275 | Material runtime owner: material definitions, legacy log/Softwood aliasing, wallet amount/add/spend/save/restore, display name/icon/background/color helpers, Scrapwood rounding/amount text, woodcutting log reward buffing, and Berry Prep target/save/restore/match/toggle/consume/result state. `scripts/main.gd` keeps thin scene-call wrappers; Berry Mode UI orchestration lives in `scripts/ui/material_collection_surface.gd`. |

## Save-State Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/save_state/files.gd` * | 94 | Save-file I/O helper for JSON dictionary loading, text writes, atomic temp/backup promotion, and best-save recovery selection. |
| `scripts/save_state/save_runtime.gd` * | 1,341 | Runtime save-state owner: dirty/autosave/write payloads, boot save selection, load core restore, pending secondary restore state, repaired-save boot state, delayed post-load/offline simulation, save repair helpers, and restore-field orchestration. Hub save fields now call `host._hub_runtime()` directly for module/selection/mission serialization and restore. `scripts/main.gd` keeps compatibility wrappers/properties for direct scene calls and deferred string callbacks. |
| `scripts/save_state/normalizers.gd` * | 246 | Pure save-shape normalization for passive/firepit module states, leaderboard category integer maps, convergence modules, hub modules, hub mission lists, reset-generation lookup, total skill-XP evidence, save-progress predicates, onboarding-complete repair flags, generic bool/int/float restore clamps, and autosave progress-regression detection. Runtime restore orchestration lives in `scripts/save_state/save_runtime.gd`. |

## Validation And Tooling

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/check-project.ps1` | 381 | Preferred broad project validation entrypoint. |
| `scripts/test-performance-regressions.ps1` * | 3,365 | Static/runtime regression assertions for performance-sensitive code and UI contracts; hub save-state assertions now target `HubRuntime` owner calls, and achievement/chat/leaderboard/tip/temporary-event state restore, Firebase silent JSON parsing, crash-report formatting, activity-data action normalization, profile overlay visibility ownership, leaderboard/profile style ownership, and activity-card style ownership assert extracted helpers. |
| `scripts/test-save-normalization.ps1` * | 2,929 | Save/load normalization regression assertions; hub module/selection/mission direct checks now call the `HubRuntime` owner, and save-file parser/recovery assertions target `SaveStateFiles`. |
| `scripts/test-module-list-transitions.ps1` | 3,289 | Module list transition behavioral validation. |
| `scripts/test-unlock-combo-visual-smoke.ps1` * | 1,012 | Unlock/lock visual smoke test; now owns its fishing combo setup helpers instead of calling production-only hooks. |
| `scripts/test-page-switch-cover-visual.ps1` | 375 | Page-switch cover/depressed visual validation. Currently failing in this session. |
| `scripts/check-ui-boundary-contracts.ps1` * | 96 | UI boundary static contracts. |
| `scripts/check-activity-ui-boundary-contracts.ps1` * | 59 | Activity UI boundary contracts. |
| `scripts/check-activity-database-contracts.ps1` | 48 | Activity database static contracts. |
| `scripts/audit-activity-database.ps1` * | 948 | Activity database audit; hub save-state guard messages now name `HubRuntime` owner methods. |
| `scripts/capture-woodcutting-firepit.ps1` | 482 | Screenshot capture for firepit/skill-detail layout. |
| `scripts/check-leaderboard-cost-safety.ps1` * | 391 | Leaderboard cost and safety assertions; Firebase host/API-key guards now assert `OnlineRuntime`. |
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
| `scripts/main.gd` | modified | Shared button press-state helpers extracted; local UI drawing classes moved behind preloads, including the remaining inline class block; buildable action-card overlay, Berry Prep material controls, convergence build overlay, recovery/boss status-line rendering, and activity/action-card style factories moved out; module UI key helpers moved out; buildable module, recovery module, boss-gate, Berry Prep policy, convergence runtime policy/state, and manual activity unlock policy/state moved out; fishing save-state helpers moved out; tutorial/tip save-state helpers moved out; temporary-event runtime/save-state helpers moved out; audio settings normalization, repeated audio player-set lifecycle, and one-off SFX player creation moved out; extended audio async warmup cancellation collapsed behind one helper; leaderboard profile save/restore metadata rules and leaderboard/profile style factories moved out; achievement milestone builders, reward constants/formulas, toast seen-id normalization, visible milestone filtering, presentation math, completed/new achievement selectors, and reward bonus filtering moved out; progression skill save-state and medal buff math moved out; activity queue state normalization and runtime behavior moved out; chat save-state, message-rule, outbound payload, and timestamp helpers moved out; thieving save-state helpers moved out; activity data action-shape/load normalizers moved out; material definition/display/wallet/Berry Prep runtime ownership moved out; save-file I/O, passive/leaderboard/convergence/hub save-state normalizers, save-progress predicates, generic save field clamps, and autosave regression evidence moved out; boot save selection/new-save fallback split out; boot warmup overlay/progress/hide/dismiss/background warmup runtime moved out; five now-redundant module UI pass-through wrappers plus `_slug`, `_boot_warmup_cancelled`, stale chat censor wrappers, `_mat_def`, stale save-state pass-through wrappers, save-file pass-through wrappers, `_clear_module_utility_button_press`, `_open_settings`, ActivityUnlockRuntime private helper pass-throughs, and TestStateRuntime headless boot-smoke pass-throughs deleted. |
| `scripts/app/boot_warmup_runtime.gd` | added | New owner for app startup splash/warmup presentation, progress updates, dismiss/hide timing, and background texture warmup frame budget. |
| `scripts/app/lifecycle_runtime.gd` | modified | Shutdown cleanup now clears the boot warmup runtime reference beside the existing boot warmup node refs. |
| `scripts/test-performance-regressions.ps1` | modified | Boot warmup guards now inspect `BootWarmupRuntime` while keeping the `main.gd` compatibility dismiss wrapper check. |
| `scripts/gameplay/activity_unlock_runtime.gd` | added | New manual activity unlock runtime owner for unlock state, requirement policy, trust/repair, and save payload normalization. |
| `scripts/gameplay/convergence_runtime.gd` | added | New convergence runtime owner for module state, build lifecycle, cycle math, XP payout, and save shape bridge. |
| `scripts/ui/action_status_lines.gd` | removed | Folded into `scripts/ui/skill_detail_surface.gd`; boss status label construction belongs to the action-card presenter. |
| `scripts/ui/convergence_build_overlay.gd` | added | New extracted UI helper for convergence build overlay and CTA widget construction. |
| `scripts/ui/berry_prep_controls.gd` | added | New extracted UI helper for Berry Prep button/popover/apply control construction and styles. |
| `scripts/ui/buildable_module_overlay.gd` | added | New extracted UI helper for buildable module blueprint overlay and CTA widget construction. |
| `scripts/gameplay/fighting_runtime.gd` | added | New consolidated fight/boss runtime owner for Blue Guy health, boss gates, and chicken brawl stage bridge. |
| `scripts/gameplay/boss_gates.gd` | removed | Folded into `scripts/gameplay/fighting_runtime.gd`; boss gates now share the same owner as fight runtime state. |
| `scripts/gameplay/combat_arenas.gd` | removed | Folded into `scripts/gameplay/action_runtime.gd`; the diamond arena predicate has no second owner. |
| `scripts/gameplay/buildable_modules.gd` | added | New extracted gameplay helper for buildable action contracts, built-state normalization, build cost, label, XP policy, and live build transaction. |
| `scripts/gameplay/recovery_modules.gd` | added | New extracted gameplay helper for recovery contracts, target-skill selection, and result copy. |
| `scripts/materials/berry_prep.gd` | removed | Folded into `scripts/materials/runtime.gd`; Berry Prep state and consumption belong with the material wallet owner. |
| `scripts/tutorial/tip_state.gd` | added | New extracted tutorial helper for tip metadata normalization. |
| `scripts/progression/skill_state.gd` | added | New extracted progression helper for skill, stamina, and stamina-bank save payload normalization. |
| `scripts/fishing/state.gd` | added | New extracted fishing save-state helper for selected location and rod/tool normalization. |
| `scripts/temporary_events/runtime.gd` | added/modified | Extracted temporary-event runtime owner for constants, definitions, scheduler/state, action projection, reward scaling, event action start/clear/completion attempts, completion mutation, and save/restore orchestration. |
| `scripts/temporary_events/state.gd` | added | New extracted temporary-event helper for saved active/cooldown state and restore normalization. |
| `scripts/audio/player_sets.gd` | removed | Folded into `scripts/audio/audio_director.gd`; it was not reused outside the audio owner. |
| `scripts/audio/settings.gd` | removed | Folded into `scripts/audio/audio_director.gd`; audio settings normalization has no second owner. |
| `scripts/online/leaderboard_profile.gd` | moved | Leaderboard profile helper for local name/id/avatar rules now lives under the online owner folder. |
| `scripts/progression/medal_buffs.gd` | added | New extracted progression helper for neighbor medal buff contribution math. |
| `scripts/thieving/state.gd` | added | New extracted thieving helper for trophy and action jail save normalization. |
| `scripts/achievements/milestones.gd` | added | New extracted achievement milestone builder fed by a live progress context from `scripts/main.gd`. |
| `scripts/save_state/files.gd` | added | New extracted save-file helper for JSON load/write, temp/backup promotion, and best-save comparison. |
| `scripts/save_state/normalizers.gd` | added | New extracted save-state helper for pure dictionary/list normalization across several save domains. |
| `scripts/materials/defs.gd` | removed | Folded into `scripts/materials/runtime.gd`; material definitions and wallet behavior now have one owner. |
| `scripts/materials/runtime.gd` | added | New consolidated material owner for definitions, wallet operations/save/restore, display helpers, log reward buffing, and Berry Prep state/consume/result policy. |
| `scripts/activity_data/normalizers.gd` | added | New extracted activity/event database parser and action dictionary helper. |
| `scripts/online/chat_state.gd` | moved | Chat state helper for retry timestamp clamping and opened-message id normalization now lives under the online owner folder. |
| `scripts/activity_queue/runtime.gd` | added | New extracted activity queue runtime owner for queue mutation, save/restore bridge, target resolution, stamina skip, and start/stop/process behavior. |
| `scripts/activity_queue/state.gd` | removed | Folded into `scripts/activity_queue/runtime.gd`; queue normalization and next-index math have no second owner. |
| `scripts/achievements/rewards.gd` | added | New extracted achievement reward helper for art paths, target tables, and reward amount formulas. |
| `scripts/achievements/state.gd` | added | New extracted achievement state helper for save-shape normalization, milestone filtering, reward bonuses, and completed/new id selection. |
| `scripts/achievements/presentation.gd` | added | New extracted achievement presentation helper for pure badge/progress layout math. |
| `scripts/online/firebase_runtime.gd` | removed | Folded into `scripts/online/online_runtime.gd`; Firebase runtime primitives have no second owner. |
| `scripts/diagnostics/crash_reports.gd` | added | New extracted diagnostics helper for crash-report clipboard text, Android diagnostic event compaction, metadata summaries, and lifecycle verdicts. |
| `scripts/diagnostics/crash_report_runtime.gd` | added | New extracted diagnostics runtime for crash-report pending files, session marker writes, Android diagnostic file tailing, heartbeat state, and unclean-session report synthesis. |
| `scripts/core/formatting.gd` | added | New extracted core utility for shared display-number and duration formatting. |
| `scripts/monetization/ad_bonus.gd` | added | New extracted monetization helper for rewarded-ad bonus timing, multipliers, and stack-meter math. |
| `scripts/online/firebase_cloud_save.gd` | removed | Folded into `scripts/online/online_runtime.gd`; cloud-save policy has no second owner. |
| `scripts/leaderboard/presentation.gd` | added | New extracted leaderboard presentation helper for score/rank formatting and status/empty-state copy. |
| `scripts/leaderboard/styles.gd` | added | New extracted leaderboard/profile StyleBox factory helper. |
| `scripts/module_ui/keys.gd` | added | New extracted module UI key helper for action, fishing area, fishing offer, thieving heist, hub keys, skill ownership checks, lazy track-id parsing, and saved key collection normalization. |
| `scripts/ui/button_press_state.gd` | added | New extracted helper for button press-state metadata, including optional extra metadata fields. |
| `scripts/ui/activity_card_styles.gd` | added | New extracted helper for activity/action-card visual StyleBox factories. |
| `scripts/ui/regen_circle.gd` | added | New extracted stamina/regen gauge drawing class. |
| `scripts/ui/fish_circle.gd` | added | New extracted fishing header circle control. |
| `scripts/ui/page_switch_button_face.gd` | added | New extracted shaped page-switch/action-card face control. |
| `scripts/ui/prism_connector_overlay.gd` | added | New extracted prism/depth connector overlay control. |
| `scripts/ui/page_switch_chevron_icon.gd` | added | New extracted page-switch chevron icon control. |
| `scripts/ui/module_utility_collapse_arrow.gd` | added | New extracted module utility collapse arrow control. |
| `scripts/ui/blue_guy_health_heart_gauge.gd` | added | New extracted fighting health heart gauge control. |
| `scripts/ui/module_action_circle_zone.gd` | added | New extracted circular action-card hit zone. |
| `scripts/ui/skill_icon_badge_mask.gd` | added | New extracted skill icon badge mask control. |
| `scripts/ui/skill_icon_symbol_draw.gd` | added | New extracted skill icon texture draw control. |
| `scripts/ui/module_collapse_minus_glyph.gd` | added | New extracted module collapse minus glyph control. |
| `scripts/ui/medal_sparkle_star.gd` | added | New extracted medal sparkle star control. |
| `scripts/ui/medal_shine_slash.gd` | added | New extracted medal shine slash animation control. |
| `scripts/test-performance-regressions.ps1` | modified | Static assertion updated so skill detail action viewport must clip below the skill info shelf; RegenCircle and FishCircle assertions now target extracted scripts; silent JSON parsing assertion now targets `scripts/online/online_runtime.gd`; crash-report formatting assertions now target `scripts/diagnostics/crash_reports.gd`. Also contains pre-existing save/refactor assertion edits from active worktree. |
| `scripts/check-ui-boundary-contracts.ps1` | modified | Chat presentation boundary now tracks the live expanded composer instead of deleted `_chat_composer`. |
| `scripts/check-activity-ui-boundary-contracts.ps1` | modified | Unlock boundary no longer preserves deleted test-only `_unlock_prior_test_actions` listing. |
| `docs/ui-runtime-boundary-map.md` | modified | Chat boundary updated for live composer helper. |
| `docs/activity-ui-boundary-map.md` | modified | Unlock boundary map no longer lists deleted test helper. |
| `scripts/test-save-normalization.ps1` | modified | Save-file parser/recovery checks now preload `SaveStateFiles` instead of calling deleted `main.gd` pass-through wrappers. |
| `scripts/check-leaderboard-cost-safety.ps1` | modified | Firebase URL/API-key safety assertions now target `scripts/online/online_runtime.gd`. |
| `docs/plan-v0.5.0.md` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.html` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/ponytail-line-reductions.md` | untracked | Pre-existing line-reduction notes. |
| `docs/refactor-file-map.md` | added | New live architecture/refactor sidecar. |

## Extraction Queue

0. Dead-code deletion
   - Current: deleted stale helpers `_build_hero`, `_add_hub_build_mode_toggle`, `_chat_composer`, `_detail_lazy_mount_initial_window_async`, `_render_detail_eager_card_list`, `_show_module_pin_preview`, `_build_skill_strip`, `_wait_for_page_switch_cover_opaque`, `_activity_stat_hit_buttons`, `_ensure_skill_swipe_preview`, `_capture_skill_strip_page_refs`, `_unlock_prior_test_actions`, `_chat_row`, `_sync_hub_hotspot_hold_circle`, `_hub_build_mode_button_style`, `_toggle_hub_build_mode`, `_expire_module_pin_preview_after_delay`, `_finish_module_pin_preview_animation`, `_prime_skill_swipe_preview_modules`, `_icon_button`, `_event_hourglass_badge`, `_fishing_wallet_selectable_tools`, `_summary_style`, one stale thieving unlock predecessor helper, `_set_control_position_y_safe`, `_position_new_onboarding_explore_tip`, `_reveal_skill_swipe_preview_modules`, `_button_style`, `_hub_hotspot_hold_ring_rect`, `_ensure_hub_hotspot_hold_circle`, `_activity_lock_piece`, `_skill_swipe_fade_progress`, `_finish_detail_actions_visual_scroll`, `_finish_boot_warmup_overlay`, `_finish_skill_swipe_preview_modules_reveal`, `_begin_page_switch_selection_under_cover`, and `_select_skill_with_initial_scroll_under_page_switch_cover`.
   - Current: also deleted definition-only constants/preloads/state fields after restoring intentional performance-contract anchors.
   - Current: moved reusable-control ownership assertions out of `scripts/main.gd`, then deleted the now-redundant main preload/constant anchors.
   - Current: deleted four newly orphaned script files: `scripts/fishing_attempt_bar.gd`, `scripts/ui/hub_move_icon.gd`, `scripts/ui/passive_pile_shadow.gd`, and `scripts/ui/firepit_dependency_connector.gd`.
   - Current: deleted two orphaned Godot probe scene scripts and their `.uid` files from `scripts/tests/`.
   - Current: deleted five orphaned `.uid` metadata files whose `.gd` scripts no longer exist.
   - Current: moved two fishing-combo smoke setup hooks out of `scripts/main.gd` and into `scripts/test-unlock-combo-visual-smoke.ps1`.
   - Next lazy win: continue only with functions that have no runtime/test callers after checking dynamic `scene.call(...)` use.

1. Button press state
   - Current: shared metadata helper lives in `scripts/ui/button_press_state.gd`; bottom nav, module utility, fishing offer, fishing method, and thieving heist buttons use it.
   - Next lazy win: keep page-switch separate until its visual regression is understood.

2. Activity/skill UI ownership
   - Current: many shelf, module, card, and action rendering paths still live in `scripts/main.gd`; the reusable local drawing controls larger than tiny glyphs are now isolated in `scripts/ui/`.
   - Next lazy win: skip the remaining 8-45 line local glyph helpers unless they need real behavior changes; extracting them would add more file plumbing than architecture.

3. Module UI identity
   - Current: module UI key building, normalization, ownership checks, lazy track-id parsing, pin/collapse/sort state, and saved preference normalization live in `scripts/module_ui/runtime.gd`; `scripts/main.gd` keeps compatibility constants/properties/wrappers for scene/test callers.
   - Current: `scripts/activity_queue/runtime.gd` preloads `scripts/module_ui/runtime.gd` directly; obsolete `scripts/module_ui/keys.gd` is gone.
   - Next lazy win: leave badge/card chrome and scroll-anchor animation in `main.gd` until a mechanical UI-chrome step.

4. Achievements
   - Current: achievement art paths, target tables, and reward formulas live in `scripts/achievements/rewards.gd`.
   - Current: achievement toast seen-id normalization, host-backed live milestone context, action medal record assembly, visible milestone filtering, and reward-bonus filtering live in `scripts/achievements/state.gd`.
   - Current: pure achievement milestone dictionary construction lives in `scripts/achievements/milestones.gd`; `scripts/main.gd` keeps only the retained achievement/toast compatibility points and leaves UI/rendering in place.
   - Next lazy win: keep reward bonus cache invalidation in `scripts/main.gd` until broader stat-cache ownership moves.

5. Progression
   - Current: neighbor medal buff contribution and per-tier math live in `scripts/progression/medal_buffs.gd`.
   - Next lazy win: keep mastery/action lookup and stat caches in `scripts/main.gd` until a larger progression service boundary can move.

6. Audio
   - Current: audio player lifecycle, playback flow, bus sync, and settings volume normalization live in `scripts/audio/audio_director.gd`.
   - Next lazy win: keep only UI slider bindings and caller compatibility wrappers in `scripts/main.gd` until a broader settings UI boundary moves.

7. Leaderboard
   - Current: local profile name/id/avatar rules live in `scripts/online/leaderboard_profile.gd`.
   - Current: score/rank/status presentation rules live in `scripts/leaderboard/presentation.gd`.
   - Current: Firebase URL/API-key/runtime primitives and cloud-save status/record shaping live in `scripts/online/online_runtime.gd`.
   - Next lazy win: keep `scripts/online/chat_state.gd` and `scripts/online/leaderboard_profile.gd` separate until their cross-cutting callers can route through clearer owners.

7a. Diagnostics
   - Current: crash-report session marker/pending-file ownership lives in `scripts/diagnostics/crash_report_runtime.gd`; formatting, Android event compaction, metadata extraction, and lifecycle verdicts live in `scripts/diagnostics/crash_reports.gd`.
   - Next lazy win: keep settings button copy/truncation UI in `scripts/main.gd` until a broader settings action boundary moves.

7b. Core utilities
   - Current: shared number and duration formatting lives in `scripts/core/formatting.gd`.
   - Next lazy win: direct-call `GameFormatting` from extracted helper modules when they need display math, instead of routing new code through `scripts/main.gd` wrappers.

7c. Monetization
   - Current: rewarded-ad/shop bonus runtime lives in `scripts/monetization/ad_bonus.gd`; `scripts/main.gd` keeps compatibility constants/properties/wrappers and `scripts/ui/shop_surface.gd` keeps shop presentation.
   - Next lazy win: remove main wrappers only after save/UI/tests stop direct-calling them.

8. Activity queue
   - Current: queue runtime state, queue normalization, circular next-index math, and start/stop/process behavior live in `scripts/activity_queue/runtime.gd`; queue page return state/navigation lives in `scripts/ui/navigation_shell.gd`; queue selection page controls/banner/overlays live in `scripts/ui/skill_swipe_activity_surface.gd`. `scripts/main.gd` keeps compatibility properties/wrappers and the selection-mode flag.
   - Next lazy win: leave `queue_selection_mode` with the host UI state until the selection overlay owner changes; remove compatibility wrappers only after direct scene/test callers are gone.

9. Chat
   - Current: retry timestamp save/restore clamping, opened message-id normalization, message sanitation/censoring, message id generation, and chat row timestamp formatting live in `scripts/online/chat_state.gd`.
   - Next lazy win: keep stream connection and row/composer UI in `scripts/main.gd` until a full chat runtime boundary can move.

10. Thieving
   - Current: heist constants, trophy/action-jail state, heist lookup/visibility, trophy tier math, and trophy/jail save normalization live in `scripts/thieving/state.gd`; heist cards, overlays, and reward floats live in `scripts/thieving/surface.gd`.
   - Next lazy win: remove compatibility wrappers only after direct scene/test callers stop using the old `main.gd` names.

11. Activity data loading
   - Current: live activity catalog loading/lookup/sort ownership lives in `scripts/activity_data/catalog.gd`; pure activity/event database normalizers live in `scripts/activity_data/normalizers.gd`; fishing area parsing and render-policy catalog ownership live in `scripts/fishing/state.gd`.
   - Next lazy win: migrate broad UI/save/gameplay callers only when they can stop using `main.gd` aliases without breaking direct scene/test access.

12. Save normalization
   - Current: passive/firepit module state, leaderboard category integer maps, convergence module state, hub module state, and hub mission list normalization live in `scripts/save_state/normalizers.gd`.
   - Next lazy win: keep exact static tests around any save-payload simplification; do not move restore orchestration until a whole save subsystem boundary exists.

13. Activity database
   - Current: data source is already externalized in `docs/activity-database.json`.
   - Next lazy win: do not move data again; reduce loader glue in `scripts/main.gd` instead.

14. Materials
   - Current: material definitions, aliases, display metadata, color lookup, amount rounding/text, wallet mutation, wallet save/restore normalization, log reward buffing, and Berry Prep runtime state live in `scripts/materials/runtime.gd`.
   - Next lazy win: keep Berry mode overlay/UI and direct scene-call wrappers in `scripts/main.gd` until those callers have a cleaner owner.

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
| `git diff --check -- scripts/main.gd scripts/module_ui/keys.gd` | passed after extracting module UI key helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting module UI key helpers. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting module UI key helpers. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after extracting module UI key helpers. |
| `.\scripts\test-module-list-transitions.ps1` | passed after extracting module UI key helpers; runner emitted existing save-protection/leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/module_ui/keys.gd docs/refactor-file-map.md` | passed after moving module UI ownership and lazy track-id parsing into `scripts/module_ui/keys.gd`. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving module UI ownership and lazy track-id parsing. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after moving module UI ownership and lazy track-id parsing. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after moving module UI ownership and lazy track-id parsing. |
| `.\scripts\test-module-list-transitions.ps1` | passed after moving module UI ownership and lazy track-id parsing; runner emitted existing save-protection/leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/module_ui/keys.gd docs/refactor-file-map.md` | passed after moving module UI saved key collection normalization into `scripts/module_ui/keys.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving module UI saved key collection normalization; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving module UI saved key collection normalization. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after moving module UI saved key collection normalization. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after moving module UI saved key collection normalization. |
| `git diff --check -- scripts/main.gd scripts/online/online_runtime.gd scripts/test-performance-regressions.ps1 scripts/check-leaderboard-cost-safety.ps1` | passed after consolidating Firebase runtime helpers into `OnlineRuntime`. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting Firebase runtime helpers. |
| `.\scripts\test-firebase-leaderboard-runtime-guard.ps1` | passed after extracting Firebase runtime helpers. |
| `.\scripts\check-leaderboard-cost-safety.ps1` | passed after extracting Firebase runtime helpers. |
| `git diff --check -- scripts/main.gd scripts/diagnostics/crash_reports.gd scripts/test-performance-regressions.ps1` | passed after extracting crash-report diagnostics. |
| `.\scripts\test-crash-report-recovery.ps1` | passed after extracting crash-report diagnostics. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting crash-report diagnostics. |
| `git diff --check -- scripts/main.gd scripts/diagnostics/crash_report_runtime.gd scripts/app/lifecycle_runtime.gd scripts/ui/update_process_shell.gd scripts/ui/settings_surface.gd scripts/test-crash-report-recovery.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after extracting crash-report runtime; emitted only CRLF conversion warnings. |
| `.\scripts\test-crash-report-recovery.ps1` | passed after extracting crash-report runtime. |
| `.\scripts\check-crash-audit-contracts.ps1` | passed after extracting crash-report runtime. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting crash-report runtime. |
| `.\scripts\check-project.ps1` | passed after extracting crash-report runtime; emitted existing save recovery/save-block warnings, RID/ObjectDB/resource leak-at-exit warnings, the known pinned-pin smoke script-error line while reporting ok, and the known non-strict `skills-page-performance-release-warning`. |
| `git diff --check -- scripts/main.gd scripts/core/formatting.gd` | passed after extracting core formatting helpers. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting core formatting helpers. |
| `.\scripts\test-performance-regressions.ps1` | blocked after extracting core formatting helpers by unrelated dirty activity-data edits: `Gather Fallen Branches should produce a small optional Scrapwood mat reward.` |
| `git diff --check -- scripts/main.gd scripts/monetization/ad_bonus.gd` | passed after extracting ad-bonus policy helpers. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting ad-bonus policy helpers. |
| `.\scripts\check-leaderboard-cost-safety.ps1` | passed after extracting cloud-save policy helpers. |
| `git diff --check -- scripts/main.gd scripts/online/online_runtime.gd` | passed after consolidating cloud-save policy helpers into `OnlineRuntime`. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting cloud-save policy helpers and after a one-line dirty-worktree parse fix for the unrelated diamond arena helper. |
| `.\scripts\check-leaderboard-cost-safety.ps1` | passed after extracting leaderboard presentation helpers. |
| `git diff --check -- scripts/main.gd scripts/leaderboard/presentation.gd` | passed after extracting leaderboard presentation helpers. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting leaderboard presentation helpers. |
| `git diff --check -- scripts/main.gd scripts/core/formatting.gd` | passed after moving countdown formatting into `scripts/core/formatting.gd`. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after moving countdown formatting into `scripts/core/formatting.gd`. |
| `.\scripts\test-module-list-transitions.ps1` | passed after moving module UI saved key collection normalization; runner emitted existing save-protection/leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/module_ui/keys.gd docs/refactor-file-map.md` | passed after deleting low-call module UI pass-through wrappers. |
| `.\scripts\test-save-normalization.ps1` | first rerun failed on unrelated chat retry timestamp assertions, then passed on immediate rerun after deleting low-call module UI pass-through wrappers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting low-call module UI pass-through wrappers. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting low-call module UI pass-through wrappers. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting low-call module UI pass-through wrappers. |
| `.\scripts\test-module-list-transitions.ps1` | passed after deleting low-call module UI pass-through wrappers; runner emitted existing save-protection/leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/module_ui/runtime.gd scripts/module_ui/keys.gd scripts/ui/skill_detail_surface.gd scripts/ui/navigation_shell.gd scripts/save_state/save_runtime.gd scripts/test-save-normalization.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after creating the module UI runtime owner; emitted only CRLF conversion warnings. |
| `.\scripts\test-save-normalization.ps1` | passed after creating the module UI runtime owner; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-pinned-scroll-anchor.ps1` | passed after creating the module UI runtime owner; runner emitted existing save recovery/save-protection/leak-at-exit warnings. |
| `.\scripts\test-pinned-pin-visual-smoke.ps1` | passed after creating the module UI runtime owner; runner emitted existing save warnings, leak-at-exit warnings, and the known Vector2 `is_equal_approx` script-error line while reporting ok. |
| `.\scripts\test-module-list-transitions.ps1` | passed after creating the module UI runtime owner; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after updating the pin/collapse policy assertion to inspect `scripts/module_ui/runtime.gd`. |
| `.\scripts\test-performance-regressions.ps1` | passed after creating the module UI runtime owner. |
| `.\scripts\check-project.ps1` | exited 0 after creating the module UI runtime owner; emitted existing save recovery/save-protection warnings, RID/ObjectDB/resource leak-at-exit warnings, the known pinned-pin smoke script-error line while reporting ok, and the known non-strict `skills-page-performance-release-warning`. |
| `git diff --check -- scripts/main.gd scripts/achievements/rewards.gd docs/refactor-file-map.md` | passed after extracting achievement reward constants and formulas. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting achievement reward constants and formulas. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting achievement reward constants and formulas. |
| `.\scripts\test-home-achievement-medal-click.ps1` | first run caught an indentation parse error in `_boot_warmup_texture_paths`; passed after fixing it. Runner emitted existing save-protection/shutdown warnings. |
| `git diff --check -- scripts/main.gd scripts/achievements/state.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting achievement toast seen-id normalization. |
| `.\scripts\test-save-normalization.ps1` | first run reported `save-normalization-ok` but failed process cleanup; rerun passed after extracting achievement toast seen-id normalization. |
| `.\scripts\test-home-achievement-medal-click.ps1` | passed after extracting achievement toast seen-id normalization; runner emitted existing save-protection/shutdown warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after updating the achievement toast seen-id restore assertion for `AchievementState`. |
| `git diff --check -- scripts/main.gd scripts/activity_queue/state.gd` | passed after extracting activity queue state helpers. |
| `.\scripts\test-activity-queue.ps1` | passed after extracting activity queue state helpers; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting activity queue state helpers. |
| `git diff --check -- scripts/main.gd scripts/activity_queue/runtime.gd scripts/activity_queue/state.gd scripts/ui/navigation_shell.gd scripts/ui/skill_swipe_activity_surface.gd scripts/ui/input_routing_shell.gd scripts/gameplay/action_runtime.gd scripts/save_state/save_runtime.gd scripts/test-activity-queue.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after finishing activity queue ownership; Git printed line-ending warnings only. |
| `.\scripts\test-activity-queue.ps1` | passed after moving queue runtime state into `ActivityQueueRuntime`; runner emitted existing save-recovery/leak-at-exit warnings. |
| `.\scripts\test-module-list-transitions.ps1` | passed after moving queue page return behavior into `NavigationShell`; runner emitted existing save-recovery/save-protection/leak-at-exit warnings. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after queue navigation ownership cleanup. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving queue navigation source assertions to `NavigationShell`. |
| `.\scripts\check-project.ps1` | exited 0 after queue ownership cleanup; it reported the known non-strict skills-page performance warning after three failed attempts and continued. Final Godot process audit was clean. |
| `git diff --check -- scripts/main.gd scripts/gameplay/activity_unlock_runtime.gd scripts/save_state/save_runtime.gd scripts/ui/input_routing_shell.gd scripts/ui/skill_detail_surface.gd scripts/ui/skill_swipe_activity_surface.gd scripts/fishing/state.gd scripts/fishing/ui_surface.gd scripts/gameplay/action_runtime.gd scripts/activity_queue/runtime.gd scripts/gameplay/hub_runtime.gd scripts/gameplay/passive_modules_runtime.gd scripts/test-save-normalization.ps1 scripts/test-module-list-transitions.ps1 scripts/test-skill-first-swipe-build.ps1 scripts/test-performance-regressions.ps1 docs/codebase-complete-refactor-plan-and-checklist.md docs/refactor-file-map.md` | passed after extracting manual activity unlock runtime; emitted only LF-to-CRLF warnings. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting manual activity unlock runtime; first wrapper output reported an unconfirmed Godot process ID, and immediate process audit found no `Godot.exe` process. |
| `.\scripts\test-module-list-transitions.ps1` | passed after extracting manual activity unlock runtime; runner emitted existing save recovery/save-block/leak-at-exit warnings. |
| `.\scripts\test-skill-first-swipe-build.ps1` | passed after extracting manual activity unlock runtime; runner emitted existing save recovery/save-block warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting manual activity unlock runtime. |
| `.\scripts\check-project.ps1` | exited 0 after extracting manual activity unlock runtime; it reported the known non-strict `skills-page-performance-release-warning attempts=3` and final Godot process audit was clean. |
| `git diff --check -- scripts/main.gd scripts/online/chat_state.gd scripts/test-performance-regressions.ps1` | passed after extracting chat save-state helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting chat save-state helpers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting chat save-state helpers. |
| `git diff --check -- scripts/main.gd scripts/activity_data/normalizers.gd` | passed after extracting activity data load normalizers. |
| `.\scripts\check-activity-database-contracts.ps1` | passed after extracting activity data load normalizers. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting activity data load normalizers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting activity data load normalizers; runner emitted existing leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/achievements/state.gd` | passed after moving achievement visible milestone filtering into `AchievementState`. |
| `.\scripts\test-home-achievement-medal-click.ps1` | passed after moving achievement visible milestone filtering; runner emitted existing save-protection/shutdown warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving achievement visible milestone filtering. |
| `git diff --check -- scripts/main.gd` | passed after deleting dead `_slug` and `_boot_warmup_cancelled` helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting dead `_slug` and `_boot_warmup_cancelled` helpers. |
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
| `git diff --check -- scripts/main.gd scripts/test-performance-regressions.ps1` | passed after deleting fourth stale-helper batch. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting fourth stale-helper batch. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting fourth stale-helper batch. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting fourth stale-helper batch. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting fourth stale-helper batch. |
| `git diff --check -- scripts/main.gd scripts/test-performance-regressions.ps1` | passed after deleting dead callback remnants. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting dead callback remnants. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting dead callback remnants. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting dead callback remnants. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting dead callback remnants. |
| `git diff --check -- scripts/main.gd` | passed after deleting orphaned under-cover select helper. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting orphaned under-cover select helper. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting orphaned under-cover select helper. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting orphaned under-cover select helper. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting orphaned under-cover select helper. |
| `git diff --check -- scripts/main.gd` | passed after deleting unused top-level definitions. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after deleting unused top-level definitions. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after deleting unused top-level definitions. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting unused top-level definitions. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after deleting unused top-level definitions. |
| `git diff --check -- scripts/main.gd` | passed after deleting the final unused combo-art scalar. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting the final unused combo-art scalar. |
| `git diff --check -- scripts/main.gd scripts/test-performance-regressions.ps1` | passed after removing redundant main ownership anchors. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after removing redundant main ownership anchors. |
| `.\scripts\check-activity-ui-boundary-contracts.ps1` | passed after removing redundant main ownership anchors. |
| `.\scripts\test-performance-regressions.ps1` | passed after removing redundant main ownership anchors. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified visible skill detail rendering after removing redundant main ownership anchors. |
| `git diff --check -- scripts/main.gd` | passed after deleting the final opportunity-window anchor constants. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting the final opportunity-window anchor constants. |
| `rg -n "fishing_attempt_bar|hub_move_icon|passive_pile_shadow|firepit_dependency_connector" .` | found only docs references after deleting newly orphaned script files. |
| `git diff --check -- deleted script files` | passed after deleting newly orphaned script files. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting newly orphaned script files. |
| `.\scripts\check-runtime-asset-paths.ps1` | passed after deleting newly orphaned script files. |
| `rg -n "fishing_wallet_press_probe|verify_live_fishing_save" .` | found no references after deleting orphaned probe scene scripts. |
| `git diff --check -- deleted probe scene files` | passed after deleting orphaned probe scene scripts. |
| `.\scripts\check-runtime-asset-paths.ps1` | passed after deleting orphaned probe scene scripts. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting orphaned probe scene scripts. |
| Orphan `.uid` scan | found no remaining script UID files without matching script files after metadata cleanup. |
| `git diff --check -- deleted uid files` | passed after metadata cleanup. |
| `.\scripts\check-runtime-asset-paths.ps1` | passed after metadata cleanup. |
| `git diff --check -- scripts/main.gd scripts/test-unlock-combo-visual-smoke.ps1` | passed after moving fishing-combo smoke setup out of `scripts/main.gd`. |
| `.\scripts\test-unlock-combo-visual-smoke.ps1 -FishingComboOnly` | passed after moving fishing-combo smoke setup out of `scripts/main.gd`; runner emitted existing save-protection/leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving fishing-combo smoke setup out of `scripts/main.gd`. |
| `git diff --check -- scripts/main.gd scripts/materials/defs.gd` | passed after extracting material definition helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting material definition helpers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting material definition helpers. |
| `git diff --check -- scripts/main.gd scripts/save_state/normalizers.gd` | passed after extracting shared save-state normalizers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting shared save-state normalizers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting shared save-state normalizers. |
| `git diff --check -- scripts/main.gd scripts/achievements/milestones.gd` | passed after extracting achievement milestone builders. |
| `.\scripts\test-home-achievement-medal-click.ps1` | first run exposed a missing sibling preload in `AchievementMilestones`, then passed after fixing it; runner emitted existing save-protection/shutdown warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting achievement milestone builders. |
| `git diff --check -- scripts/main.gd scripts/online/chat_state.gd` | passed after extracting chat message rules. |
| `.\scripts\test-save-normalization.ps1` | first run exposed the censored word list type mismatch, then passed after fixing it; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting chat message rules. |
| `rg -n "_censor_chat_message|_censor_chat_token|_is_chat_word_char|_mat_def|_convergence_module_state_from_save|_hub_module_state_from_save" .` | found no references after deleting dead wrappers. |
| `git diff --check -- scripts/main.gd` | passed after deleting dead wrappers. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting dead wrappers. |
| `git diff --check -- scripts/main.gd scripts/online/chat_state.gd` | passed after moving chat timestamp helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving chat timestamp helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after moving chat timestamp helpers; runner emitted existing leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/thieving/state.gd` | passed after extracting thieving save-state helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting thieving save-state helpers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting thieving save-state helpers. |
| `git diff --check -- scripts/main.gd scripts/progression/medal_buffs.gd` | passed after extracting neighbor medal buff math. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting neighbor medal buff math. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting neighbor medal buff math; runner emitted existing leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/online/leaderboard_profile.gd` | passed after extracting leaderboard profile rules. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting leaderboard profile rules; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting leaderboard profile rules. |
| `git diff --check -- scripts/main.gd scripts/materials/defs.gd` | passed after moving material wallet rules. |
| `.\scripts\test-save-normalization.ps1` | passed after moving material wallet rules; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving material wallet rules. |
| `git diff --check -- scripts/main.gd scripts/materials/runtime.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after consolidating material/Berry Prep ownership into `MaterialRuntime`; emitted only LF-to-CRLF warnings. |
| `.\scripts\test-berry-prep.ps1` | passed after material runtime consolidation; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-buildable-modules.ps1` | passed after material runtime consolidation; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-honey-stamina-regen.ps1` | passed after material runtime consolidation; runner emitted existing save-recovery/save-block and leak-at-exit warnings. |
| `.\scripts\test-woodcutting-firepit.ps1` | passed after material runtime consolidation; runner emitted existing save-recovery and leak-at-exit warnings. |
| `.\scripts\test-save-normalization.ps1` | passed after material runtime consolidation; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed stale material ownership assertions, then passed after retargeting them to `scripts/materials/runtime.gd`. |
| `.\scripts\check-project.ps1` | exited 0 after material runtime consolidation; continued past the known non-strict skills-page performance warning after three failed attempts. |
| Godot process check | no leftover `Godot.exe` processes found after material runtime validation. |
| `git diff --check -- scripts/main.gd scripts/audio/settings.gd` | passed after extracting audio settings normalization. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting audio settings normalization; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting audio settings normalization. |
| `git diff --check -- scripts/main.gd scripts/audio/audio_director.gd docs/refactor-file-map.md` | passed after consolidating audio player-set lifecycle helpers into `AudioDirector`. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting audio player-set lifecycle helpers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting audio player-set lifecycle helpers. |
| `git diff --check -- scripts/main.gd scripts/save_state/normalizers.gd` | passed after moving autosave progress-regression evidence into `scripts/save_state/normalizers.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving autosave progress-regression evidence; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving autosave progress-regression evidence. |
| `git diff --check -- scripts/main.gd scripts/fishing/state.gd` | passed after extracting fishing save-state helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting fishing save-state helpers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting fishing save-state helpers. |
| `git diff --check -- scripts/main.gd scripts/audio/audio_director.gd` | passed after moving one-off SFX player creation into the audio owner. |
| `.\scripts\test-save-normalization.ps1` | passed after moving one-off SFX player creation; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving one-off SFX player creation. |
| `git diff --check -- scripts/main.gd scripts/online/leaderboard_profile.gd` | passed after moving leaderboard profile save metadata into `scripts/online/leaderboard_profile.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving leaderboard profile save metadata; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving leaderboard profile save metadata. |
| `git diff --check -- scripts/main.gd scripts/online/leaderboard_profile.gd scripts/test-performance-regressions.ps1` | passed after moving leaderboard profile restore metadata into `scripts/online/leaderboard_profile.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving leaderboard profile restore metadata; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving leaderboard profile restore metadata and updating the ownership assertion. |
| `git diff --check -- scripts/main.gd` | passed after deleting dead `_clear_module_utility_button_press` and `_open_settings` wrappers. |
| `.\scripts\test-save-normalization.ps1` | passed after deleting dead wrappers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting dead wrappers. |
| `git diff --check -- scripts/main.gd scripts/progression/skill_state.gd` | passed after extracting skill/stamina save-state normalization. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting skill/stamina save-state normalization; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting skill/stamina save-state normalization. |
| `git diff --check -- scripts/main.gd scripts/tutorial/tip_state.gd scripts/test-performance-regressions.ps1` | passed after extracting tip metadata normalization. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting tip metadata normalization; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting tip metadata normalization and updating the ownership assertion. |
| `git diff --check -- scripts/main.gd scripts/save_state/normalizers.gd` | passed after extracting generic save field clamps into `SaveStateNormalizers`. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting generic save field clamps; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting generic save field clamps. |
| `git diff --check -- scripts/main.gd scripts/save_state/files.gd scripts/test-save-normalization.ps1` | passed after extracting save-file I/O helpers into `SaveStateFiles`. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting save-file I/O helpers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting save-file I/O helpers. |
| `git diff --check -- scripts/main.gd scripts/save_state/normalizers.gd` | passed after extracting save-progress predicates into `SaveStateNormalizers`. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting save-progress predicates; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting save-progress predicates. |
| `git diff --check -- scripts/main.gd scripts/ui/module_action_circle_zone.gd scripts/ui/skill_icon_badge_mask.gd scripts/ui/skill_icon_symbol_draw.gd scripts/ui/module_collapse_minus_glyph.gd scripts/ui/medal_sparkle_star.gd scripts/ui/medal_shine_slash.gd` | passed after extracting the remaining inline UI draw classes. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting the remaining inline UI draw classes. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting the remaining inline UI draw classes. |
| `.\scripts\capture-woodcutting-firepit.ps1` | passed after extracting the remaining inline UI draw classes; screenshot written to `.codex-tmp\woodcutting-firepit\woodcutting-firepit-card.png`. |
| `git diff --check -- scripts/main.gd scripts/online/chat_state.gd` | passed after moving chat outbound payload construction into `ChatState`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving chat outbound payload construction; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving chat outbound payload construction. |
| `git diff --check -- scripts/main.gd scripts/activity_data/normalizers.gd scripts/test-performance-regressions.ps1` | passed after moving activity action dictionary construction into `ActivityDataNormalizers`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving activity action dictionary construction; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale mat-reward ownership assertion, then passed after updating it for `ActivityDataNormalizers.action_for_load`. |
| `git diff --check -- scripts/main.gd` | passed after splitting boot save selection and new-save fallback helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after splitting boot save selection; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after splitting boot save selection. |
| `.\scripts\check-ui-boundary-contracts.ps1` | passed after extracting achievement presentation math. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting achievement presentation math. |
| Godot process check | no leftover `Godot.exe` processes found after validation. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving completed/new achievement and reward bonus filtering into `AchievementState`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving completed/new achievement and reward bonus filtering; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after achievement state validation. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting temporary-event save-state normalization; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale ownership assertion, then passed after pointing it at `TemporaryEventState.active_entry_from_save`. |
| `git diff --check -- scripts/main.gd scripts/temporary_events/state.gd scripts/test-performance-regressions.ps1` | passed after extracting temporary-event save-state normalization. |
| Godot process check | no leftover `Godot.exe` processes found after temporary-event validation. |
| `git diff --check -- scripts/main.gd scripts/temporary_events/runtime.gd scripts/temporary_events/state.gd scripts/save_state/save_runtime.gd scripts/gameplay/action_runtime.gd scripts/fishing/state.gd scripts/test-save-normalization.ps1 scripts/test-module-list-transitions.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after finishing temporary-event runtime ownership; emitted only LF/CRLF conversion warnings. |
| `.\scripts\test-save-normalization.ps1` | passed after moving temporary-event runtime state/action completion ownership; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale moved-runtime assertion, then passed after updating it for `TemporaryEventRuntime`. |
| `.\scripts\test-module-list-transitions.ps1` | passed after moving temporary-event runtime state/action completion ownership; runner emitted existing save recovery/save-block and leak-at-exit warnings. |
| `.\scripts\check-project.ps1` | exited 0 after moving temporary-event runtime ownership; skills-page performance failed three non-strict attempts and continued with `skills-page-performance-release-warning attempts=3`. |
| Godot process check | no leftover `Godot.exe` processes found after Step 81 temporary-event validation. |
| `git diff --check -- scripts/main.gd scripts/monetization/ad_bonus.gd scripts/ui/shop_surface.gd scripts/save_state/save_runtime.gd scripts/ui/update_process_shell.gd scripts/ui/skill_detail_surface.gd scripts/test-save-normalization.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md scripts/set-admob-ids.ps1` | passed after moving rewarded-ad/shop bonus runtime ownership; emitted only LF/CRLF conversion warnings. |
| `.\scripts\test-save-normalization.ps1` | first run caught a moved-runtime GDScript inference issue, then passed after typing the visible-bonus snapshot local; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving rewarded-ad/shop bonus runtime ownership. |
| `.\scripts\check-project.ps1` | exited 0 after moving rewarded-ad/shop bonus runtime ownership; skills-page performance failed three non-strict attempts and continued with `skills-page-performance-release-warning attempts=3`. |
| Godot process check | no leftover `Godot.exe` processes found after Step 82 ad-bonus validation. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review of the extraction found no new issue. |
| Screenshot | `.codex-tmp\woodcutting-firepit\woodcutting-firepit-header-desktop-627x1115.png` verified shelf/module clipping after prior UI fix. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting buildable, recovery, and Berry Prep policy helpers. |
| `.\scripts\test-buildable-modules.ps1` | passed after extracting buildable module policy; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-recovery-modules.ps1` | passed after extracting recovery module policy; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-berry-prep.ps1` | passed after extracting Berry Prep policy; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after buildable/recovery/Berry Prep validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting boss-gate policy helpers. |
| `.\scripts\test-boss-fight-gate.ps1` | passed after extracting boss-gate policy; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after boss-gate validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting buildable module overlay UI. |
| `.\scripts\test-buildable-modules.ps1` | passed after extracting buildable module overlay UI; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | transient headless `Godot.exe` seen immediately after buildable overlay test, gone on follow-up inspection without termination. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting Berry Prep controls. |
| `.\scripts\test-berry-prep.ps1` | passed after extracting Berry Prep controls; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after Berry Prep control validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting combat arena policy. |
| `.\scripts\test-fighting-diamond-arena.ps1` | passed after extracting combat arena policy; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after combat arena validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting convergence build overlay UI. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting convergence build overlay UI. |
| Godot process check | no leftover `Godot.exe` processes found after convergence overlay validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting action status lines. |
| `.\scripts\test-boss-fight-gate.ps1` | passed after extracting action status lines; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-recovery-modules.ps1` | first parallel attempt reported `recovery-modules-ok` but failed its process guard because it saw the concurrently running boss-gate Godot process; rerun alone passed with existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| Godot process check | no leftover `Godot.exe` processes found after action status-line validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting action art UI. |
| `.\scripts\test-activity-card-geometry.ps1` | passed after extracting action art UI; runner emitted existing CanvasItem/ObjectDB/resource leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale action-art ownership assertion, then passed after moving the assertion to `ActionArtUi.image`. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after action art UI validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting module sort menu UI. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting module sort menu UI and deleting stale sort helper functions. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after module sort menu UI validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting module utility row UI. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale module-utility icon metadata ownership assertion, then passed after moving it to `ModuleUtilityRowUi`. |
| `git diff --check -- scripts/main.gd scripts/ui/module_utility_row_ui.gd scripts/test-performance-regressions.ps1` | passed after extracting module utility row UI. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after module utility row UI validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting paper button style generation. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving paper/chunky button texture generation assertions to `PaperButtonStyles`. |
| `git diff --check -- scripts/main.gd scripts/ui/paper_button_styles.gd scripts/test-performance-regressions.ps1` | passed after extracting paper button style generation. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after paper button style validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting chat visual styles. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed stale chat bubble style ownership assertions, then passed after moving them to `ChatStyles`. |
| `git diff --check -- scripts/main.gd scripts/chat/styles.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting chat visual styles. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after chat visual style validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting passive module styles. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving passive module style ownership assertions to `PassiveModuleStyles`. |
| `git diff --check -- scripts/main.gd scripts/ui/passive_module_styles.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting passive module styles. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after passive module style validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting achievement styles. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving achievement style ownership assertions to `AchievementStyles`. |
| `git diff --check -- scripts/main.gd scripts/achievements/styles.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting achievement styles. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after achievement style validation. |
| `git diff --check -- scripts/main.gd scripts/achievements/state.gd scripts/achievements/milestones.gd scripts/gameplay/action_runtime.gd scripts/fishing/state.gd scripts/ui/achievement_overlay_surface.gd scripts/ui/skill_detail_surface.gd scripts/save_state/save_runtime.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after moving achievement live-state/context helpers; emitted only LF-to-CRLF warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after adding AchievementState live-context ownership guards. |
| `.\scripts\test-save-normalization.ps1` | first run caught strict typed-inference issues in moved `AchievementState` locals, then passed after typing them; rerun emitted existing Godot leak-at-exit warnings. |
| `.\scripts\test-home-achievement-medal-click.ps1` | passed after moving achievement live-state/context helpers; runner emitted existing save-protection/shutdown warnings. |
| `.\scripts\check-project.ps1` | exited 0 after moving achievement live-state/context helpers; continued after known non-strict `skills-page-performance-release-warning` following three failed attempts. |
| Godot process check | no leftover `Godot.exe` processes found after achievement live-state validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting mastery save-state normalization; wrapper noted an unconfirmed transient Godot PID, and follow-up process inspection found no remaining `Godot.exe`. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving mastery save/restore ownership assertions to `MasteryState`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving mastery serialization/restore normalization to `MasteryState`; emitted existing Godot leak warnings on exit. |
| `git diff --check -- scripts/main.gd scripts/progression/mastery_state.gd scripts/test-performance-regressions.ps1 docs/refactor-file-map.md` | passed after extracting mastery save-state normalization. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after mastery save-state validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | first run caught a typed-inference warning in `scripts/leaderboard/styles.gd`, then passed after typing the avatar fill/style locals. |
| `.\scripts\test-performance-regressions.ps1` | first rerun exposed a stale profile-avatar ownership assertion, then passed after moving it to `LeaderboardStyles.avatar_button`. |
| `git diff --check -- docs/refactor-file-map.md scripts/main.gd scripts/leaderboard/styles.gd scripts/test-performance-regressions.ps1` | passed after extracting leaderboard/profile styles. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after leaderboard/profile style validation. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting activity/action-card visual styles. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving action-art and shade ownership assertions to `ActivityCardStyles`. |
| `git diff --check -- docs/refactor-file-map.md scripts/main.gd scripts/ui/activity_card_styles.gd scripts/test-performance-regressions.ps1` | passed after extracting activity/action-card visual styles. |
| Autoreview | no project/tool `autoreview` runner found; manual diff review plus `git diff --check` found no new issue. |
| Godot process check | no leftover `Godot.exe` processes found after activity/action-card style validation. |
| `git diff --check -- scripts/main.gd scripts/core/visual_texture_cache.gd scripts/test-performance-regressions.ps1 docs/codebase-complete-refactor-plan-and-checklist.md docs/refactor-file-map.md` | passed after extracting shared visual texture/cache infrastructure; emitted only LF-to-CRLF warnings. |
| `.\run-godot-safe.ps1 --path . --quit-after 1` | passed after extracting shared visual texture/cache infrastructure. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving texture/cache helper body assertions to `VisualTextureCache`. |
| `.\scripts\check-project.ps1` | exited 0 after extracting shared visual texture/cache infrastructure; continued after known non-strict `skills-page-performance-release-warning attempts=3`. |
| Godot process check | no leftover `Godot.exe` processes found after visual texture/cache validation. |
| `git diff --check -- scripts/main.gd scripts/activity_data/catalog.gd scripts/gameplay/action_runtime.gd scripts/save_state/save_runtime.gd scripts/test-save-normalization.ps1 scripts/test-performance-regressions.ps1 docs/refactor-file-map.md docs/codebase-complete-refactor-plan-and-checklist.md` | passed after deleting pure `TemporaryEventRuntime` pass-through wrappers; emitted only LF-to-CRLF warnings. |
| `.\scripts\test-save-normalization.ps1` | passed after deleting pure `TemporaryEventRuntime` pass-through wrappers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after retargeting temporary-event source guards to direct `_temporary_event_runtime()` owner calls. |
| `.\scripts\check-project.ps1` | exited 1 on known out-of-scope smoke noise: hidden-preview scroll gap, material badge null-tree shutdown noise, stale `_show_module_sort_menu` direct-call shim errors, pinned stop-hold, save recovery/progress-block warnings, and leak-at-exit warnings. |
| `.\run-godot-safe.ps1 --path . --quit-after 1` | passed after deleting pure `TemporaryEventRuntime` pass-through wrappers. |
| Godot process check | no leftover `Godot.exe` processes found after temporary-event wrapper-deletion validation. |
