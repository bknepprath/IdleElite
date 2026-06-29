# Idle Slop 1 Refactor Map

Last updated: 2026-06-29

Purpose: living sidecar for the refactor. Keep this file updated when code moves, files are extracted, or session-touched files change.

Legend:
- `*` affected this session
- `(collapsed)` media/generated-heavy tree; counted by file count instead of line-by-line

## Session Notes

- Current main target: shrink `scripts/main.gd` by moving real ownership boundaries out, then delete dead code when proven.
- Active extraction rule: only extract code with a real second caller, a clear ownership boundary, or a naming win that lets local code use short names honestly.
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
| `scripts/` | 246 files / about 114,735 counted text lines | Game runtime script, UI drawing helpers, validation, build, and maintenance scripts. |
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
| `scripts/main.gd` * | 64,380 | Monolithic game controller: save/load, activity data, skill UI, navigation, fishing, leaderboard, chat, hub, audio, and most orchestration. Primary deletion/refactor target; recent UI drawing controls, action art UI, module sort menu UI, module utility row UI, paper button style generation, passive module styles, buildable module overlay, Berry Prep controls, convergence build overlay, recovery/boss status lines, and remaining inline draw classes now preload from `scripts/ui/`, module UI key construction/parsing/save-shape normalization now preloads from `scripts/module_ui/`, buildable/recovery/boss-gate/combat-arena gameplay policy now preloads from `scripts/gameplay/`, fishing save-state helpers now preload from `scripts/fishing/`, tutorial/tip save-state helpers now preload from `scripts/tutorial/`, temporary-event save-state helpers now preload from `scripts/temporary_events/`, audio player-set construction and settings normalization now preload from `scripts/audio/`, leaderboard profile/save/restore rules, presentation copy/score/rank formatting, and leaderboard/profile style factories now preload from `scripts/leaderboard/`, Firebase URL/key/runtime primitives and cloud-save record/status shaping now preload from `scripts/firebase/`, crash-report formatting/lifecycle diagnostics now preload from `scripts/diagnostics/`, number/duration/countdown display formatting now preloads from `scripts/core/`, ad-bonus duration/multiplier/stack math now preloads from `scripts/monetization/`, achievement milestone/reward/state/presentation/style helpers now preload from `scripts/achievements/`, progression skill save-state, mastery save-state, and medal buff math now preload from `scripts/progression/`, activity queue state helpers now preload from `scripts/activity_queue/`, chat save-state, message-rule, timestamp, outbound payload helpers, and chat visual styles now preload from `scripts/chat/`, thieving save-state helpers now preload from `scripts/thieving/`, activity data parser/action-shape helpers now preload from `scripts/activity_data/`, material definition/display/wallet/berry-prep helpers now preload from `scripts/materials/`, and save file I/O, shared save-state normalizers, save-progress predicates, generic field clamps, plus autosave regression evidence now preload from `scripts/save_state/`; boot save selection is split into focused helpers. |

## Core Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/core/formatting.gd` * | 77 | Shared number and time formatting: stamina cost text, info-chip/significant-digit/compact/percent display, trailing-zero trimming, short duration text, and countdown timers. `scripts/main.gd` keeps compatibility wrappers for existing call sites. |
| `scripts/perf_monitor.gd` | 206 | Runtime performance monitor. |
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
| `scripts/ui/button_press_state.gd` * | 70 | Shared press/drag/release metadata helper for passive button routing. Extracted from `scripts/main.gd` this session. |
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
| `scripts/ui/activity_progress_rail.gd` | 295 | Activity progress rail drawing. |
| `scripts/ui/activity_progress_opportunity_overlay.gd` | 206 | Opportunity overlay drawing. |
| `scripts/ui/action_status_lines.gd` * | 22 | Compact recovery/boss status label construction for action cards. `scripts/main.gd` computes the text and domain state. |
| `scripts/ui/action_art_ui.gd` * | 95 | Action art image construction, animated art setup, corner badges, border overlay, and headless-safe texture/mask decisions. `scripts/main.gd` supplies texture callbacks and game-specific icon paths. |
| `scripts/ui/module_sort_menu_ui.gd` * | 113 | Module sort menu construction, sort button styling, active-state sync, and button depress hookup. `scripts/main.gd` owns sort preferences and screen refresh. |
| `scripts/ui/module_utility_row_ui.gd` * | 102 | Module utility row, nav buttons, icon metadata, and collapse toggle construction. `scripts/main.gd` owns navigation callbacks, visibility, and row motion state. |
| `scripts/ui/paper_button_styles.gd` * | 128 | Procedural paper/chunky button StyleBoxTexture generation, rounded-rect pixel tests, cache fill, and headless fallback texture wiring. `scripts/main.gd` keeps compatibility wrappers and theme callbacks. |
| `scripts/ui/passive_module_styles.gd` * | 102 | Passive module currency/stat/popup/icon/plank/round/upgrade StyleBox factories. `scripts/main.gd` passes current panel, ink, gold, and theme callbacks while passive callsites keep stable names. |
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
| `scripts/ui/berry_prep_controls.gd` * | 141 | Berry Prep material-module button, hint badge, popover copy, apply button, and local styles. `scripts/main.gd` supplies live action/state text and callbacks. |
| `scripts/ui/buildable_module_overlay.gd` * | 95 | Buildable action-card blueprint overlay and centered CTA panel. `scripts/main.gd` computes build text/affordability and receives the expected widget dictionary. |
| `scripts/ui/convergence_build_overlay.gd` * | 97 | Convergence action-card build overlay, countdown label, and shrine CTA panel. Runtime countdown/status updates stay in `scripts/main.gd`. |
| `scripts/ui/module_action_circle_zone.gd` * | 6 | Circular action-card hit zone formerly embedded in `scripts/main.gd`. |
| `scripts/ui/skill_icon_badge_mask.gd` * | 18 | Skill icon badge mask control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/skill_icon_symbol_draw.gd` * | 14 | Skill icon texture draw control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/module_collapse_minus_glyph.gd` * | 19 | Module collapse minus glyph formerly embedded in `scripts/main.gd`. |
| `scripts/ui/medal_sparkle_star.gd` * | 30 | Achievement medal sparkle star control formerly embedded in `scripts/main.gd`. |
| `scripts/ui/medal_shine_slash.gd` * | 46 | Achievement medal shine slash animation control formerly embedded in `scripts/main.gd`. |

## Module UI Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/module_ui/keys.gd` * | 133 | Module UI key prefixes, normalization, action key construction, ownership checks, lazy track-id parsing, saved order/flag/path normalization, and fishing action alias canonicalization. Extracted so module UI code can use local names like `action_id`, `prefix`, and `key` without mega-script prefixes. |

## Achievement Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/achievements/rewards.gd` * | 41 | Achievement art paths, target tables, and stamina reward formulas. First achievement ownership cut; live milestone state remains in `scripts/main.gd` for now. |
| `scripts/achievements/state.gd` * | 112 | Achievement save-state normalization, completed/new achievement filtering, reward-bonus filtering, toast seen-id mutation, and visible milestone filtering. |
| `scripts/achievements/milestones.gd` * | 209 | Achievement milestone dictionary builders for total level, action medal log entries, tier counts, cumulative medals, and crit milestones. `scripts/main.gd` now only gathers live progress context. |
| `scripts/achievements/presentation.gd` * | 40 | Achievement presentation math: skill-level target sequence, medal cluster counts/positions, and progress percentages used by home/log UI. |
| `scripts/achievements/styles.gd` * | 32 | Achievement card, toast queue badge, and skill-section StyleBox factories. `scripts/main.gd` keeps compatibility wrappers and passes the shared surface-style callback. |

## Progression Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/progression/skill_state.gd` * | 46 | Skill XP/level, stamina, and stamina-bank save payload normalization over skill definitions. Runtime XP gain and stamina regen remain in `scripts/main.gd`. |
| `scripts/progression/mastery_state.gd` * | 40 | Mastery save/restore normalization: canonical action keys, duplicate-key max XP, level derivation, and max-level XP clamping. Runtime mastery XP gain and visual medal behavior remain in `scripts/main.gd`. |
| `scripts/progression/medal_buffs.gd` * | 50 | Neighbor medal buff contribution and per-tier math. `scripts/main.gd` still owns cache, playable-action selection, and mastery lookups. |

## Gameplay Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/gameplay/boss_gates.gd` * | 58 | Boss fight and boss-gate policy: boss id/name extraction, completed-boss save/restore filtering, and missing requirement checks. Live completion mutation remains in `scripts/main.gd`. |
| `scripts/gameplay/buildable_modules.gd` * | 75 | Buildable module policy: action keys, build contract checks, built-state save/restore filtering, cost dictionaries, labels, and XP rewards. Live wallet spend, XP mutation, render refresh, and save calls remain in `scripts/main.gd`. |
| `scripts/gameplay/combat_arenas.gd` * | 8 | Combat arena policy: currently the diamond arena shape predicate used by fighting card UI. |
| `scripts/gameplay/recovery_modules.gd` * | 45 | Recovery module policy: recovery contracts, target-skill selection including lowest-stamina targeting, and result text. Live stamina mutation remains in `scripts/main.gd`. |

## Leaderboard Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/leaderboard/profile.gd` * | 156 | Leaderboard profile avatar clamping, display-name cleanup, name-key generation/validation, guest-name detection/generation, player-id generation/sanitization, profile save/restore metadata, auth provider normalization, and refresh-token cleanup. |
| `scripts/leaderboard/presentation.gd` * | 126 | Leaderboard display policy: score/rank text, submit status title/detail copy, simple status normalization, and empty-state detail copy. Row state, scoring, and UI nodes remain in `scripts/main.gd`. |
| `scripts/leaderboard/styles.gd` * | 99 | Leaderboard dropdown/player-card/rank-badge StyleBox factories plus profile avatar/name-field StyleBox factories. `scripts/main.gd` keeps callsite-compatible wrappers and passes current theme callbacks. |

## Firebase Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/firebase/runtime.gd` * | 122 | Firebase runtime primitives: silent JSON parsing, database URL/API-key sanitization, official Realtime Database host allowlisting, REST URL construction, server timestamp payloads, error-body detail extraction, and stream target parsing. |
| `scripts/firebase/cloud_save.gd` * | 69 | Cloud-save policy helpers: Google-account readiness, status text, summary dictionaries, payload-size guarded JSON, and Firebase record construction. HTTP request lifecycle remains in `scripts/main.gd`. |

## Diagnostics Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/diagnostics/crash_reports.gd` * | 197 | Crash-report clipboard formatting, Android diagnostic event compaction, build/device metadata extraction, previous-session summary text, and Android lifecycle verdict helpers. Runtime file I/O and settings button behavior remain in `scripts/main.gd`. |

## Monetization Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/monetization/ad_bonus.gd` * | 42 | Rewarded-ad bonus policy: XP/speed multipliers, status text, countdown ticking, stack grants, and shop stack-meter counts/units. Rewarded-ad plugin callbacks and UI refresh remain in `scripts/main.gd`. |

## Audio Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/audio/player_sets.gd` * | 37 | Shared AudioStreamPlayer lifecycle helpers: dispose existing lists, append path-backed player sets, append repeated player pools with volume stepping, and ensure one-off path-backed SFX players. Used by extended audio warmup/build code. |
| `scripts/audio/settings.gd` * | 10 | Audio settings save/restore volume normalization. Runtime playback and bus sync remain in `scripts/main.gd`. |

## Fishing Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/fishing/state.gd` * | 57 | Fishing save-state helpers for selected location normalization, equipped-tool save fallback, and rod collection hierarchy/reconciliation. Fishing UI, offer actions, and live catch logic remain in `scripts/main.gd`. |

## Tutorial Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/tutorial/tip_state.gd` * | 29 | Tip metadata save/restore normalization: lock/passive/silver opportunity tip flags, action-key cleanup, and bounded recent detail-pull tip text history. Tutorial UI sequencing remains in `scripts/main.gd`. |

## Temporary Event Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/temporary_events/state.gd` * | 82 | Temporary-event save payload and restore normalization for active entries, cooldowns, legacy field names, event-definition validation, and minimum-level restore gates. Runtime scheduling/action/UI behavior remains in `scripts/main.gd`. |

## Activity Queue Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/activity_queue/state.gd` * | 23 | Activity queue save/list normalization and ring-index math. Queueability and target resolution remain in `scripts/main.gd` because they depend on live unlock/action state. |

## Chat Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/chat/state.gd` * | 172 | Chat save-state clamping, last-opened message id normalization, message whitespace/censor/max-length sanitation, message id generation, outbound Firebase payload/update construction, and Central-time timestamp formatting. Stream/UI behavior remains in `scripts/main.gd`. |
| `scripts/chat/styles.gd` * | 109 | Global chat strip, unread dot, message bubble, back button, input, and keyboard preview StyleBox factories. `scripts/main.gd` passes current ink/focus colors and keeps callsite-compatible wrappers. |

## Thieving Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/thieving/state.gd` * | 61 | Thieving trophy and action-jail save-state normalization. Runtime heist/action lookup remains in `scripts/main.gd`. |

## Activity Data Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/activity_data/normalizers.gd` * | 321 | Pure activity/event database load normalization: action dictionary construction, event module records, requirements, XP/resource rewards, tag arrays, art animation metadata, resource paths, and slugs. |

## Material Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/materials/defs.gd` * | 107 | Material id normalization, definition/display metadata lookup, amount rounding, wallet amount/add/spend rules, and save/restore normalization. UI amount text remains in `scripts/main.gd` for shared number formatting. |
| `scripts/materials/berry_prep.gd` * | 70 | Berry Prep targeting, save/restore normalization, match checks, XP bonus application, and result text. Material spending and badge/UI refresh remain in `scripts/main.gd`. |

## Save-State Helper Scripts

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/save_state/files.gd` * | 94 | Save-file I/O helper for JSON dictionary loading, text writes, atomic temp/backup promotion, and best-save recovery selection. Runtime save/load orchestration and timestamps remain in `scripts/main.gd`. |
| `scripts/save_state/normalizers.gd` * | 246 | Pure save-shape normalization for passive/firepit module states, leaderboard category integer maps, convergence modules, hub modules, hub mission lists, reset-generation lookup, total skill-XP evidence, save-progress predicates, onboarding-complete repair flags, generic bool/int/float restore clamps, and autosave progress-regression detection. Runtime restore orchestration remains in `scripts/main.gd`. |

## Validation And Tooling

| Path | Lines | What lives here |
| --- | ---: | --- |
| `scripts/check-project.ps1` | 381 | Preferred broad project validation entrypoint. |
| `scripts/test-performance-regressions.ps1` * | 3,095 | Static/runtime regression assertions for performance-sensitive code and UI contracts; achievement/chat/leaderboard/tip/temporary-event state restore, Firebase silent JSON parsing, crash-report formatting, activity-data action normalization, and leaderboard/profile style ownership now assert extracted helpers. |
| `scripts/test-save-normalization.ps1` * | 2,883 | Save/load normalization regression assertions; save-file parser/recovery assertions now target `SaveStateFiles`. |
| `scripts/test-module-list-transitions.ps1` | 3,289 | Module list transition behavioral validation. |
| `scripts/test-unlock-combo-visual-smoke.ps1` * | 1,012 | Unlock/lock visual smoke test; now owns its fishing combo setup helpers instead of calling production-only hooks. |
| `scripts/test-page-switch-cover-visual.ps1` | 375 | Page-switch cover/depressed visual validation. Currently failing in this session. |
| `scripts/check-ui-boundary-contracts.ps1` * | 96 | UI boundary static contracts. |
| `scripts/check-activity-ui-boundary-contracts.ps1` * | 59 | Activity UI boundary contracts. |
| `scripts/check-activity-database-contracts.ps1` | 48 | Activity database static contracts. |
| `scripts/audit-activity-database.ps1` | 870 | Activity database audit. |
| `scripts/capture-woodcutting-firepit.ps1` | 482 | Screenshot capture for firepit/skill-detail layout. |
| `scripts/check-leaderboard-cost-safety.ps1` * | 391 | Leaderboard cost and safety assertions; Firebase host/API-key guards now assert the extracted runtime helper. |
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
| `scripts/main.gd` | modified | Shared button press-state helpers extracted; local UI drawing classes moved behind preloads, including the remaining inline class block; buildable action-card overlay, Berry Prep material controls, convergence build overlay, and recovery/boss status-line rendering moved out; module UI key helpers moved out; buildable module, recovery module, boss-gate, and Berry Prep policy moved out; fishing save-state helpers moved out; tutorial/tip save-state helpers moved out; temporary-event save-state helpers moved out; audio settings normalization, repeated audio player-set lifecycle, and one-off SFX player creation moved out; extended audio async warmup cancellation collapsed behind one helper; leaderboard profile save/restore metadata rules and leaderboard/profile style factories moved out; achievement milestone builders, reward constants/formulas, toast seen-id normalization, visible milestone filtering, presentation math, completed/new achievement selectors, and reward bonus filtering moved out; progression skill save-state and medal buff math moved out; activity queue state normalization moved out; chat save-state, message-rule, outbound payload, and timestamp helpers moved out; thieving save-state helpers moved out; activity data action-shape/load normalizers moved out; material definition/display/wallet helpers moved out; save-file I/O, passive/leaderboard/convergence/hub save-state normalizers, save-progress predicates, generic save field clamps, and autosave regression evidence moved out; boot save selection/new-save fallback split out; five now-redundant module UI pass-through wrappers plus `_slug`, `_boot_warmup_cancelled`, stale chat censor wrappers, `_mat_def`, stale save-state pass-through wrappers, save-file pass-through wrappers, `_clear_module_utility_button_press`, and `_open_settings` deleted. |
| `scripts/ui/action_status_lines.gd` | added | New extracted UI helper for recovery/boss status labels in action cards. |
| `scripts/ui/convergence_build_overlay.gd` | added | New extracted UI helper for convergence build overlay and CTA widget construction. |
| `scripts/ui/berry_prep_controls.gd` | added | New extracted UI helper for Berry Prep button/popover/apply control construction and styles. |
| `scripts/ui/buildable_module_overlay.gd` | added | New extracted UI helper for buildable module blueprint overlay and CTA widget construction. |
| `scripts/gameplay/boss_gates.gd` | added | New extracted gameplay helper for boss identity, completion save state, and prerequisite checks. |
| `scripts/gameplay/combat_arenas.gd` | added | New extracted gameplay helper for combat arena shape predicates. |
| `scripts/gameplay/buildable_modules.gd` | added | New extracted gameplay helper for buildable action contracts, built-state normalization, build cost, label, and XP policy. |
| `scripts/gameplay/recovery_modules.gd` | added | New extracted gameplay helper for recovery contracts, target-skill selection, and result copy. |
| `scripts/materials/berry_prep.gd` | added | New extracted material helper for Berry Prep target/save/match/consume/result policy. |
| `scripts/tutorial/tip_state.gd` | added | New extracted tutorial helper for tip metadata normalization. |
| `scripts/progression/skill_state.gd` | added | New extracted progression helper for skill, stamina, and stamina-bank save payload normalization. |
| `scripts/fishing/state.gd` | added | New extracted fishing save-state helper for selected location and rod/tool normalization. |
| `scripts/temporary_events/state.gd` | added | New extracted temporary-event helper for saved active/cooldown state and restore normalization. |
| `scripts/audio/player_sets.gd` | added | New extracted audio helper for repeated player-list lifecycle used by sync and async extended audio warmup. |
| `scripts/audio/settings.gd` | added | New extracted audio settings helper for save/restore volume clamping. |
| `scripts/leaderboard/profile.gd` | added | New extracted leaderboard profile helper for local name/id/avatar rules. |
| `scripts/progression/medal_buffs.gd` | added | New extracted progression helper for neighbor medal buff contribution math. |
| `scripts/thieving/state.gd` | added | New extracted thieving helper for trophy and action jail save normalization. |
| `scripts/achievements/milestones.gd` | added | New extracted achievement milestone builder fed by a live progress context from `scripts/main.gd`. |
| `scripts/save_state/files.gd` | added | New extracted save-file helper for JSON load/write, temp/backup promotion, and best-save comparison. |
| `scripts/save_state/normalizers.gd` | added | New extracted save-state helper for pure dictionary/list normalization across several save domains. |
| `scripts/materials/defs.gd` | added | New extracted material helper for id aliases, metadata lookup, display names/icons/backgrounds/colors, and amount rounding. |
| `scripts/activity_data/normalizers.gd` | added | New extracted activity/event database parser and action dictionary helper. |
| `scripts/chat/state.gd` | added | New extracted chat state helper for retry timestamp clamping and opened-message id normalization. |
| `scripts/activity_queue/state.gd` | added | New extracted activity queue state helper for queue normalization and next-index math. |
| `scripts/achievements/rewards.gd` | added | New extracted achievement reward helper for art paths, target tables, and reward amount formulas. |
| `scripts/achievements/state.gd` | added | New extracted achievement state helper for save-shape normalization, milestone filtering, reward bonuses, and completed/new id selection. |
| `scripts/achievements/presentation.gd` | added | New extracted achievement presentation helper for pure badge/progress layout math. |
| `scripts/firebase/runtime.gd` | added | New extracted Firebase runtime helper for silent JSON parsing, sanitized config, allowlisted database URL construction, server timestamps, error detail extraction, and stream target parsing. |
| `scripts/diagnostics/crash_reports.gd` | added | New extracted diagnostics helper for crash-report clipboard text, Android diagnostic event compaction, metadata summaries, and lifecycle verdicts. |
| `scripts/core/formatting.gd` | added | New extracted core utility for shared display-number and duration formatting. |
| `scripts/monetization/ad_bonus.gd` | added | New extracted monetization helper for rewarded-ad bonus timing, multipliers, and stack-meter math. |
| `scripts/firebase/cloud_save.gd` | added | New extracted Firebase cloud-save helper for account readiness, status copy, summary, payload JSON limits, and record construction. |
| `scripts/leaderboard/presentation.gd` | added | New extracted leaderboard presentation helper for score/rank formatting and status/empty-state copy. |
| `scripts/leaderboard/styles.gd` | added | New extracted leaderboard/profile StyleBox factory helper. |
| `scripts/module_ui/keys.gd` | added | New extracted module UI key helper for action, fishing area, fishing offer, thieving heist, hub keys, skill ownership checks, lazy track-id parsing, and saved key collection normalization. |
| `scripts/ui/button_press_state.gd` | added | New extracted helper for button press-state metadata, including optional extra metadata fields. |
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
| `scripts/test-performance-regressions.ps1` | modified | Static assertion updated so skill detail action viewport must clip below the skill info shelf; RegenCircle and FishCircle assertions now target extracted scripts; silent JSON parsing assertion now targets `scripts/firebase/runtime.gd`; crash-report formatting assertions now target `scripts/diagnostics/crash_reports.gd`. Also contains pre-existing save/refactor assertion edits from active worktree. |
| `scripts/check-ui-boundary-contracts.ps1` | modified | Chat presentation boundary now tracks the live expanded composer instead of deleted `_chat_composer`. |
| `scripts/check-activity-ui-boundary-contracts.ps1` | modified | Unlock boundary no longer preserves deleted test-only `_unlock_prior_test_actions` listing. |
| `docs/ui-runtime-boundary-map.md` | modified | Chat boundary updated for live composer helper. |
| `docs/activity-ui-boundary-map.md` | modified | Unlock boundary map no longer lists deleted test helper. |
| `scripts/test-save-normalization.ps1` | modified | Save-file parser/recovery checks now preload `SaveStateFiles` instead of calling deleted `main.gd` pass-through wrappers. |
| `scripts/check-leaderboard-cost-safety.ps1` | modified | Firebase URL/API-key safety assertions now target `scripts/firebase/runtime.gd`. |
| `docs/plan-v0.5.0.md` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/plan-v0.5.0.html` | modified | Pre-existing active worktree changes; not yet owned by this map pass. |
| `docs/ponytail-line-reductions.md` | untracked | Pre-existing line-reduction notes. |
| `docs/refactor-file-map.md` | added | New live architecture/refactor sidecar. |

## Extraction Queue

0. Dead-code deletion
   - Current: deleted stale helpers `_build_hero`, `_add_hub_build_mode_toggle`, `_chat_composer`, `_detail_lazy_mount_initial_window_async`, `_render_detail_eager_card_list`, `_show_module_pin_preview`, `_build_skill_strip`, `_wait_for_page_switch_cover_opaque`, `_activity_stat_hit_buttons`, `_ensure_skill_swipe_preview`, `_capture_skill_strip_page_refs`, `_unlock_prior_test_actions`, `_chat_row`, `_sync_hub_hotspot_hold_circle`, `_hub_build_mode_button_style`, `_toggle_hub_build_mode`, `_expire_module_pin_preview_after_delay`, `_finish_module_pin_preview_animation`, `_prime_skill_swipe_preview_modules`, `_icon_button`, `_event_hourglass_badge`, `_fishing_wallet_selectable_tools`, `_summary_style`, `_thieving_heist_preceding_action_unlocked`, `_set_control_position_y_safe`, `_position_new_onboarding_explore_tip`, `_reveal_skill_swipe_preview_modules`, `_button_style`, `_hub_hotspot_hold_ring_rect`, `_ensure_hub_hotspot_hold_circle`, `_activity_lock_piece`, `_skill_swipe_fade_progress`, `_finish_detail_actions_visual_scroll`, `_finish_boot_warmup_overlay`, `_finish_skill_swipe_preview_modules_reveal`, `_begin_page_switch_selection_under_cover`, and `_select_skill_with_initial_scroll_under_page_switch_cover`.
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
   - Current: module UI key building, normalization, ownership checks, lazy track-id parsing, and saved key collection normalization live in `scripts/module_ui/keys.gd`; `scripts/main.gd` keeps thin wrappers to avoid broad call-site churn.
   - Current: deleted the lowest-call pass-through wrappers once callers could use `ModuleUiKeys` directly.
   - Next lazy win: leave `_normalized_module_ui_key()` in place until a whole module UI state/routing slice can move; it still has dozens of callers, so renaming it now would be churn.

4. Achievements
   - Current: achievement art paths, target tables, and reward formulas live in `scripts/achievements/rewards.gd`.
   - Current: achievement toast seen-id normalization and visible milestone filtering live in `scripts/achievements/state.gd`.
   - Current: achievement milestone dictionary construction lives in `scripts/achievements/milestones.gd`; `scripts/main.gd` gathers live progress context and leaves UI/rendering in place.
   - Next lazy win: keep achievement UI rendering in `scripts/main.gd` until a whole overlay/page boundary can move.

5. Progression
   - Current: neighbor medal buff contribution and per-tier math live in `scripts/progression/medal_buffs.gd`.
   - Next lazy win: keep mastery/action lookup and stat caches in `scripts/main.gd` until a larger progression service boundary can move.

6. Audio
   - Current: audio settings save/restore volume normalization lives in `scripts/audio/settings.gd`.
   - Next lazy win: keep runtime playback/bus sync in `scripts/main.gd` until a whole audio runtime boundary can move.

7. Leaderboard
   - Current: local profile name/id/avatar rules live in `scripts/leaderboard/profile.gd`.
   - Current: score/rank/status presentation rules live in `scripts/leaderboard/presentation.gd`.
   - Current: Firebase URL/API-key/runtime primitives live in `scripts/firebase/runtime.gd`.
   - Current: Firebase cloud-save status, summary, payload JSON limit, and record shaping live in `scripts/firebase/cloud_save.gd`.
   - Next lazy win: keep Firebase request state in `scripts/main.gd` until leaderboard/chat/cloud-save network state can move as a full boundary.

7a. Diagnostics
   - Current: crash-report clipboard formatting, Android event compaction, metadata extraction, and lifecycle verdicts live in `scripts/diagnostics/crash_reports.gd`.
   - Next lazy win: keep crash marker file I/O in `scripts/main.gd` until a broader diagnostics/session runtime can own `user://` paths and heartbeat writes.

7b. Core utilities
   - Current: shared number and duration formatting lives in `scripts/core/formatting.gd`.
   - Next lazy win: direct-call `GameFormatting` from extracted helper modules when they need display math, instead of routing new code through `scripts/main.gd` wrappers.

7c. Monetization
   - Current: rewarded-ad bonus multiplier, countdown, grant, and stack-meter math lives in `scripts/monetization/ad_bonus.gd`.
   - Next lazy win: keep AdMob plugin lifecycle and visible shop UI in `scripts/main.gd` until a full monetization runtime can own the ad object callbacks.

8. Activity queue
   - Current: queue normalization and circular next-index math live in `scripts/activity_queue/state.gd`.
   - Next lazy win: keep queue UI/runtime in `scripts/main.gd` until queue target resolution can move with unlock/action access.

9. Chat
   - Current: retry timestamp save/restore clamping, opened message-id normalization, message sanitation/censoring, message id generation, and chat row timestamp formatting live in `scripts/chat/state.gd`.
   - Next lazy win: keep stream connection and row/composer UI in `scripts/main.gd` until a full chat runtime boundary can move.

10. Thieving
   - Current: trophy and action jail save normalization lives in `scripts/thieving/state.gd`.
   - Next lazy win: move heist card/state chunks only if a whole thieving UI/runtime boundary can move, not one-off callbacks.

11. Activity data loading
   - Current: pure activity/event database normalizers live in `scripts/activity_data/normalizers.gd`.
   - Next lazy win: fishing area parsing is still nearby, but it has more live database/state coupling and should move only with its dependent helpers.

12. Save normalization
   - Current: passive/firepit module state, leaderboard category integer maps, convergence module state, hub module state, and hub mission list normalization live in `scripts/save_state/normalizers.gd`.
   - Next lazy win: keep exact static tests around any save-payload simplification; do not move restore orchestration until a whole save subsystem boundary exists.

13. Activity database
   - Current: data source is already externalized in `docs/activity-database.json`.
   - Next lazy win: do not move data again; reduce loader glue in `scripts/main.gd` instead.

14. Materials
   - Current: material definition lookup, aliases, display metadata, color lookup, amount rounding, wallet mutation, and wallet save/restore normalization live in `scripts/materials/defs.gd`.
   - Next lazy win: keep amount display text in `scripts/main.gd` until shared number formatting moves.

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
| `git diff --check -- scripts/main.gd scripts/firebase/runtime.gd scripts/test-performance-regressions.ps1 scripts/check-leaderboard-cost-safety.ps1` | passed after extracting Firebase runtime helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting Firebase runtime helpers. |
| `.\scripts\test-firebase-leaderboard-runtime-guard.ps1` | passed after extracting Firebase runtime helpers. |
| `.\scripts\check-leaderboard-cost-safety.ps1` | passed after extracting Firebase runtime helpers. |
| `git diff --check -- scripts/main.gd scripts/diagnostics/crash_reports.gd scripts/test-performance-regressions.ps1` | passed after extracting crash-report diagnostics. |
| `.\scripts\test-crash-report-recovery.ps1` | passed after extracting crash-report diagnostics. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting crash-report diagnostics. |
| `git diff --check -- scripts/main.gd scripts/core/formatting.gd` | passed after extracting core formatting helpers. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting core formatting helpers. |
| `.\scripts\test-performance-regressions.ps1` | blocked after extracting core formatting helpers by unrelated dirty activity-data edits: `Gather Fallen Branches should produce a small optional Scrapwood mat reward.` |
| `git diff --check -- scripts/main.gd scripts/monetization/ad_bonus.gd` | passed after extracting ad-bonus policy helpers. |
| `.\run-godot-safe.ps1 --headless --path . --quit-after 1` | passed after extracting ad-bonus policy helpers. |
| `.\scripts\check-leaderboard-cost-safety.ps1` | passed after extracting cloud-save policy helpers. |
| `git diff --check -- scripts/main.gd scripts/firebase/cloud_save.gd` | passed after extracting cloud-save policy helpers. |
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
| `git diff --check -- scripts/main.gd scripts/chat/state.gd scripts/test-performance-regressions.ps1` | passed after extracting chat save-state helpers. |
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
| `git diff --check -- scripts/main.gd scripts/chat/state.gd` | passed after extracting chat message rules. |
| `.\scripts\test-save-normalization.ps1` | first run exposed the censored word list type mismatch, then passed after fixing it; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting chat message rules. |
| `rg -n "_censor_chat_message|_censor_chat_token|_is_chat_word_char|_mat_def|_convergence_module_state_from_save|_hub_module_state_from_save" .` | found no references after deleting dead wrappers. |
| `git diff --check -- scripts/main.gd` | passed after deleting dead wrappers. |
| `.\scripts\test-performance-regressions.ps1` | passed after deleting dead wrappers. |
| `git diff --check -- scripts/main.gd scripts/chat/state.gd` | passed after moving chat timestamp helpers. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving chat timestamp helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after moving chat timestamp helpers; runner emitted existing leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/thieving/state.gd` | passed after extracting thieving save-state helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting thieving save-state helpers; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting thieving save-state helpers. |
| `git diff --check -- scripts/main.gd scripts/progression/medal_buffs.gd` | passed after extracting neighbor medal buff math. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting neighbor medal buff math. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting neighbor medal buff math; runner emitted existing leak-at-exit warnings. |
| `git diff --check -- scripts/main.gd scripts/leaderboard/profile.gd` | passed after extracting leaderboard profile rules. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting leaderboard profile rules; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting leaderboard profile rules. |
| `git diff --check -- scripts/main.gd scripts/materials/defs.gd` | passed after moving material wallet rules. |
| `.\scripts\test-save-normalization.ps1` | passed after moving material wallet rules; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving material wallet rules. |
| `git diff --check -- scripts/main.gd scripts/audio/settings.gd` | passed after extracting audio settings normalization. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting audio settings normalization; runner emitted existing leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting audio settings normalization. |
| `git diff --check -- scripts/main.gd scripts/audio/player_sets.gd docs/refactor-file-map.md` | passed after extracting audio player-set lifecycle helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting audio player-set lifecycle helpers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting audio player-set lifecycle helpers. |
| `git diff --check -- scripts/main.gd scripts/save_state/normalizers.gd` | passed after moving autosave progress-regression evidence into `scripts/save_state/normalizers.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving autosave progress-regression evidence; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving autosave progress-regression evidence. |
| `git diff --check -- scripts/main.gd scripts/fishing/state.gd` | passed after extracting fishing save-state helpers. |
| `.\scripts\test-save-normalization.ps1` | passed after extracting fishing save-state helpers; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after extracting fishing save-state helpers. |
| `git diff --check -- scripts/main.gd scripts/audio/player_sets.gd` | passed after moving one-off SFX player creation into `scripts/audio/player_sets.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving one-off SFX player creation; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving one-off SFX player creation. |
| `git diff --check -- scripts/main.gd scripts/leaderboard/profile.gd` | passed after moving leaderboard profile save metadata into `scripts/leaderboard/profile.gd`. |
| `.\scripts\test-save-normalization.ps1` | passed after moving leaderboard profile save metadata; runner emitted existing CanvasItem/RID/ObjectDB leak-at-exit warnings. |
| `.\scripts\test-performance-regressions.ps1` | passed after moving leaderboard profile save metadata. |
| `git diff --check -- scripts/main.gd scripts/leaderboard/profile.gd scripts/test-performance-regressions.ps1` | passed after moving leaderboard profile restore metadata into `scripts/leaderboard/profile.gd`. |
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
| `git diff --check -- scripts/main.gd scripts/chat/state.gd` | passed after moving chat outbound payload construction into `ChatState`. |
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
