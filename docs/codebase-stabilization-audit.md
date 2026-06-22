# Codebase Stabilization Audit

Last updated: 2026-06-14

## Architecture Audit

- `scripts/main.gd` is the highest-risk surface. It owns data loading, save restore, UI construction, activity execution, offline progress, audio, hub state, leaderboard state, and tutorial state in one file, so small patches can touch unrelated behavior by accident.
- Activity data is the most important source-of-truth boundary. `docs/activity-database.json` is the intended owner for skills, actions, unlocks, rewards, costs, art, backgrounds, and fishing areas.
- Save/load and unlock state are coupled to activity data through string keys. Any duplicate action generation path can create save drift, missing mastery keys, wrong unlock ceremonies, or UI cards that do not match the database.
- Fishing has the clearest data ownership model, but it still depends on several constants for tools, catch art, and special unlock affordances. That should be simplified only in small follow-up phases.
- UI refresh and input flows are broad and stateful. They should be cleaned only after data ownership is stable, because many visual tests already cover regressions there.

## Cleanup Plan

1. Make activity data single-source. Remove generated/fallback action construction and stale fishing-area fallback data. Validate the JSON and exported project path.
2. Tighten save/unlock helpers. Keep one canonical key path for action ids, manual unlocks, passive unlocks, and fishing aliases.
3. Split low-risk pure helpers out of `main.gd`, starting with formatting, key canonicalization, and activity database parsing.
4. Add focused validation for source-of-truth rules: every activity action must appear in `actions_by_key`, every fishing area must map to at least one method, and exported presets must include the database.
5. Only after those are stable, simplify UI refresh paths around activity cards and skill detail scrolling.

## Latest Validation

- `.\scripts\audit-activity-database.ps1` passed on 2026-06-14.
- `.\scripts\test-save-normalization.ps1` passed on 2026-06-14.
- `.\scripts\test-performance-regressions.ps1` passed on 2026-06-14.
- `.\scripts\check-project.ps1` passed on 2026-06-14, including the focused save-payload/fishing-selection/thieving-state/leaderboard-score/chat-metadata/passive-restore normalization gate and the skills page performance gate.
- Verified no headless Godot process remained after each approved Godot validation command.

## Completed Phase 1: Activity Data Source Of Truth

Risk reduced: `main.gd` could silently generate a different activity set from asset folders if `docs/activity-database.json` failed to load. That fallback used stale short action lists and computed tuning, so broken data could become a different game instead of a validation failure.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity database loading
- Fishing area loading
- Obsolete generated action fallback code
- Activity data validation guardrails

Behavior intentionally preserved:
- Normal gameplay data still loads from `docs/activity-database.json`.
- Exported builds still include the database through `export_presets.cfg`.
- Skill/action lookup tables are still rebuilt after the database loads.

Behavior intentionally removed:
- Silent asset-folder action generation when the activity database is missing or invalid.
- Built-in fallback fishing areas that duplicated a stale subset of `fishing.areas[]`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now also verifies exported builds include `docs/activity-database.json` and that obsolete activity fallback tokens are absent from `scripts/main.gd`.
- `.\scripts\check-project.ps1` progressed through smoke, performance monitor, performance regressions, activity card geometry, tutorial start scroll, stamina gauge fail-shake, skill detail bottom scroll pad, and hidden-preview scroll-gap, then failed in the existing skills page performance budget for `swipe/build`.
- `.\scripts\test-skills-page-performance.ps1` was rerun and failed the same `swipe/build` budget.

Remaining risks:
- The Godot project check is blocked by skills page performance budget failures unrelated to activity data loading.
- `main.gd` remains a large mixed-ownership script.
- Save/unlock canonicalization still has several call sites and should be audited next.

## Completed Phase 2: Manual Unlock Save Ownership

Risk reduced: manual activity unlocks were restored and saved as raw dictionary keys. Old fishing action aliases and obsolete passive unlock keys could survive in save data even though activity lookup and passive unlock behavior now have clearer owners.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Manual activity unlock restore path
- Manual activity unlock save serialization
- Passive module unlock ownership
- Activity data audit guardrails

Behavior intentionally preserved:
- Level 1 actions still unlock automatically.
- Non-passive activities still require both a manual unlock key and the required skill level.
- Fishing action aliases are still accepted on load and normalized to canonical action ids.
- Passive woodcutting modules are still unlocked by skill level and still seed their starting stored logs once.

Behavior intentionally removed:
- Passive module unlocks are no longer written into `manual_activity_unlocks`, because passive unlock state is level-driven.
- Invalid, unknown, alias-only, or passive manual unlock keys are not re-saved.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now also rejects raw manual unlock serialization/restoration tokens.
- `.\scripts\check-project.ps1` passed smoke, performance monitor, performance regressions, activity card geometry, tutorial start scroll, stamina gauge fail-shake, skill detail bottom scroll pad, and hidden-preview scroll-gap. It remains blocked at the existing `swipe/build` skills page p99 budget.
- Verified no headless Godot process remained after validation.

Remaining risks:
- Skills page performance remains a watchpoint because repeated runs alternate around the p99 budget.
- `main.gd` still owns too many systems.
- Action key canonicalization is cleaner, but still embedded in the monolith rather than isolated behind a small activity/save helper module.

## Completed Phase 3: Persisted Action-Key Normalization

Risk reduced: mastery save data and action-key save fields could keep malformed, alias-only, or deleted action keys even after the activity database became the source of truth. Those keys could inflate global mastery checks or preserve stale tutorial/opportunity state that no current activity owns.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Mastery save serialization
- Mastery restore path
- Persisted action-key canonicalization
- Activity data audit guardrails

Behavior intentionally preserved:
- Valid mastery XP and medal levels still restore and save under canonical `skill:action` keys.
- Fishing action aliases are still accepted when loading old save data.
- Duplicate legacy keys that map to the same current action keep the highest XP value instead of depending on JSON iteration order.

Behavior intentionally removed:
- Malformed action keys without `:` are no longer preserved.
- Unknown or deleted action keys are no longer restored into mastery or saved back out.
- Raw `mastery` dictionaries are no longer written directly to save data.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now also rejects raw mastery serialization/restoration tokens.
- `.\scripts\check-project.ps1` passed, including the skills page performance gate.
- Verified no headless Godot process remained after validation.

Remaining risks:
- Mastery/action key helpers still live inside `main.gd`; extraction into a small helper module remains a future cleanup.
- Other save domains, especially hub missions and tutorial state, still use broad dictionaries and should be audited in small phases.
- Skills page performance has shown run-to-run variance, so UI work should remain isolated from data/save cleanup.

## Completed Phase 4: Remaining Save Field Normalization

Risk reduced: several small save fields were defensively canonicalized on restore but still written raw. A stale in-memory key could therefore keep cycling through saves until a later launch cleaned it, making save behavior harder to reason about.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Running action save serialization
- Thieving jail save serialization
- Fishing location selection save serialization
- Silver opportunity action-key save serialization
- Crash-session running action id payload
- Activity data audit guardrails

Behavior intentionally preserved:
- Valid running activity ids still save under the current canonical action id.
- Active thieving jail cooldowns still save with their resume flag.
- Valid fishing area/location selections still save under canonical area ids.
- Valid silver opportunity anchors still save under canonical `skill:action` keys.

Behavior intentionally removed:
- Invalid or unknown running action ids are not persisted.
- Expired, malformed, or unknown thieving jail entries are not persisted.
- Unknown fishing areas or location ids are not persisted.
- Invalid silver opportunity action keys are not persisted.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now also rejects raw save serialization for selected fishing locations, thieving jails, running action id, and silver opportunity action key.
- `.\run-godot-safe.ps1 --headless --path . --quit-after 1` passed.
- `.\scripts\check-project.ps1` has passed after this phase, including the save-normalization gate added in Phase 5.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Save/load regression coverage now covers normalization helpers directly, but not a full disk round trip through `save_game()` and `load_game()`.
- Hub mission state already normalizes on restore/sync, but save serialization is still broad and should be isolated in a later phase.
- Skills page performance remains variable and should be handled separately from save-state ownership.

## Completed Phase 5: Save Normalization Validation

Risk reduced: save-state ownership changes were covered by static guardrails and broad project checks, but there was no focused runtime test proving the normalizers drop stale keys and preserve valid state.

Files changed:
- `scripts/test-save-normalization.ps1`
- `scripts/check-project.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Save normalization validation
- Project validation sequencing
- Static regression coverage for save-state guardrails

Behavior intentionally preserved:
- The test uses the existing activity database and save helper functions without writing player save files.
- Project validation still runs the existing smoke, UI, and performance gates.

Behavior intentionally removed:
- None.

Validation:
- `.\scripts\test-save-normalization.ps1` passed. It covers mastery restore/save, fishing location save, thieving jail save, running action save, and action-key save normalization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts that `check-project.ps1` runs the save-normalization test.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate.
- Verified no headless Godot process remained after validation.

Remaining risks:
- The save-normalization test directly exercises helper behavior, not a full disk round trip.
- `check-project.ps1` still prints known dummy-renderer/shutdown noise from Godot even when it exits successfully.
- Broader save domains such as hub missions and leaderboard/chat cooldowns remain outside this focused normalization test.

## Completed Phase 6: Save Payload Extraction

Risk reduced: `save_game()` built the whole save dictionary inline while also opening, writing, flushing, and closing the save file. That made the exact serialized payload hard to test without touching a real player save file, and it made future save-field edits easier to miss in focused validation.

Files changed:
- `scripts/main.gd`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Save payload construction
- Save normalization validation
- Static regression coverage for save payload ownership

Behavior intentionally preserved:
- `save_game()` still writes the same save schema and field set to `SAVE_PATH`.
- Valid mastery, fishing selections, thieving jails, running action ids, and silver opportunity keys are still saved under canonical current keys.
- The test still avoids writing player save files.

Behavior intentionally removed:
- None.

Validation:
- `.\scripts\test-save-normalization.ps1` passed. It now verifies `_save_payload(now)` uses the save normalizers and supplied timestamp.
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the focused save test covers `_check_save_payload`.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This validates the payload builder directly, not the physical disk round trip through `FileAccess`.
- Broad save domains such as hub missions, leaderboard credentials, and chat cooldown metadata still serialize as broad dictionaries.
- `main.gd` still owns save, activity data, UI, runtime action execution, and offline progression in one script.

## Completed Phase 7: Ignored Leaderboard Provider Save Field Removal

Risk reduced: `leaderboard_auth_provider` was persisted and read from save data, but restore immediately overwrote it to `"anonymous"`. That made the save schema imply a supported provider choice that did not actually exist, creating compatibility noise for future leaderboard patches.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard auth save serialization
- Leaderboard auth restore path
- Save payload validation
- Activity audit guardrails

Behavior intentionally preserved:
- Runtime leaderboard auth still defaults to `"anonymous"`.
- Auth completion still falls back to `"anonymous"` if the runtime field is ever empty.
- Refresh tokens, retry cooldowns, player id, name claim state, and leaderboard scores still save and restore normally.

Behavior intentionally removed:
- Save files no longer write the ignored `leaderboard_auth_provider` field.
- Loading no longer reads `leaderboard_auth_provider` from save data before overwriting it.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects save/restore persistence of the ignored provider field.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts that save-payload validation checks this field stays omitted.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies `_save_payload(now)` omits `leaderboard_auth_provider`.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Leaderboard save state still has several related fields and should only be changed with the cost-safety checks in mind.
- The physical save-file round trip remains untested; current coverage validates the payload helper and load-path code statically.
- `check-project.ps1` still prints known Godot shutdown leak/resource noise after successful runs.

## Completed Phase 8: Passive Module Restore Deduplication

Risk reduced: passive module save restore had two separate loops rebuilding the same six-field module state. Primary load and deferred secondary load could drift if a future patch changed clamping, timestamps, seeded state, or stored resources in only one path.

Files changed:
- `scripts/main.gd`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Passive module save restore
- Deferred secondary save restore
- Focused restore validation
- Static regression coverage for restore duplication

Behavior intentionally preserved:
- Primary restore still loads valid passive module entries from `passive_modules`.
- Secondary restore still preserves already-restored module entries and only fills missing ones.
- Malformed passive module entries are still skipped.
- Passive module fields still use the same clamping/default rules as before.

Behavior intentionally removed:
- The duplicate inline passive-module restore loop in `_load_game_secondary_restore()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts there is only one `loaded_passive_modules` restore loop and that secondary restore uses preserve-existing mode.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies primary passive restore and preserve-existing secondary restore behavior.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Passive module save serialization still writes the broad runtime dictionary directly.
- The test exercises the helper directly, not a full physical save-file round trip.
- `main.gd` still owns passive modules, save/load, activity execution, UI, and offline progression in one script.

## Completed Phase 9: Fishing Selection Save/Restore Normalization

Risk reduced: fishing area/location selections were normalized on save but restored raw. That allowed malformed, deleted, or unknown saved selections to live in memory until a later save or UI correction, which made fishing selection state less predictable than the payload schema.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing selected-location restore
- Fishing selected-location save serialization
- Shared fishing selection validation
- Static regression coverage for raw restore paths

Behavior intentionally preserved:
- Valid fishing area/location selections still restore and save under canonical area ids.
- Valid save payload behavior is unchanged.

Behavior intentionally removed:
- Malformed `selected_fishing_locations` data no longer leaves stale selections in memory after restore.
- Unknown fishing areas or deleted location ids are dropped on restore instead of only being dropped on the next save.
- The old raw restore assignment to `selected_fishing_locations[_canonical_fishing_area_id(...)]` was removed.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects the old raw fishing-selection restore token.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing selection save and restore use `_normalized_selected_fishing_locations()`.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies malformed restore data clears selections and valid restore data survives.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still prints Godot dummy-renderer/shutdown noise after successful runs. The latest run also printed a transient RID/null-texture backtrace in the skills page performance cleanup path while still exiting successfully.
- The focused test validates helper behavior, not a physical save-file round trip.
- Fishing tool/catch state still has several specialized restore branches and should be simplified only in smaller follow-up phases.

## Completed Phase 10: Thieving Jail Save/Restore Normalization

Risk reduced: thieving jail state had separate save and restore parsers deciding which action cooldowns were valid. That duplicated action-id canonicalization, expiry filtering, and resume flag handling, while the restore path also carried a legacy scalar cooldown format.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Thieving jail save serialization
- Thieving jail restore
- Save/restore validation for legacy jail cooldowns
- Static regression coverage for raw jail restore paths

Behavior intentionally preserved:
- Valid active thieving jail cooldowns still save and restore under canonical action ids.
- Dictionary jail entries still preserve `resume_when_free`.
- Legacy scalar cooldown entries still restore, with `resume_when_free` defaulting to `false`.
- Expired, malformed, or unknown action jail entries are still dropped.

Behavior intentionally removed:
- The inline `loaded_thieving_action_jails` parser in `_load_game_core()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects the old raw thieving jail restore token.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts thieving jail save and restore use `_normalized_thieving_action_jails()`.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies malformed jail data clears state, valid dictionary jail entries survive, and legacy scalar cooldowns still restore.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The test validates helper behavior, not a physical save-file round trip.
- Thieving trophy state has a separate restore path and can be reviewed in a later small phase.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 11: Thieving Trophy Save/Restore Normalization

Risk reduced: thieving trophy state restored through a helper but still saved the raw runtime dictionary. Unknown trophy ids or malformed trophy entries could therefore remain in saved data even though runtime behavior only uses `THIEVING_HEIST_DEFS`.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Thieving trophy save serialization
- Thieving trophy restore
- Save payload validation for trophy state
- Static regression coverage for raw trophy persistence

Behavior intentionally preserved:
- Known trophy ids still save and restore `stolen` and `cooldown_until_unix`.
- Legacy boolean trophy saves still restore as stolen/un-stolen trophy state.
- Legacy `cooldown_until_unix_msec` restore fallback is still accepted.

Behavior intentionally removed:
- Unknown trophy ids are dropped on restore/save.
- Malformed trophy entries are not saved back out.
- Raw `thieving_trophies` dictionaries are no longer written directly to the save payload.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw thieving trophy save/restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts trophy payload and restore paths use `_normalized_thieving_trophies()`.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies dictionary trophy restore, legacy boolean restore, unknown id dropping, and normalized trophy payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The test validates helper behavior, not a physical save-file round trip.
- Trophy runtime state can still be initialized by `_ensure_all_thieving_trophy_state()` for all known heists; that is intentional but remains coupled to the heist definition list.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 12: Leaderboard Category Score Save Normalization

Risk reduced: leaderboard submitted scores were normalized on restore but saved as the raw runtime dictionary. Unknown or stale category keys could therefore persist in save data even though leaderboard reads and writes only understand the current category list.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard category score save serialization
- Save payload validation for leaderboard state
- Static regression coverage for raw leaderboard category persistence

Behavior intentionally preserved:
- Valid leaderboard category scores still save under canonical category ids.
- Scores are still clamped to nonnegative values on persistence.
- Unknown category ids still map through `_leaderboard_valid_category_id()`; if multiple keys map to the same canonical category, the highest score is kept.

Behavior intentionally removed:
- Raw `leaderboard_last_submitted_scores_by_category` is no longer written directly to the save payload.
- Unknown leaderboard category keys are no longer preserved in saved payloads.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw leaderboard category score serialization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_leaderboard_last_submitted_scores_for_save()`.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies canonical category score serialization and payload output.
- `.\scripts\check-project.ps1` initially failed the known variable `swipe/build` skills-page p99 performance gate, then passed on rerun with the same save-normalization gate included.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The test validates helper behavior, not a physical save-file round trip.
- Leaderboard fetch retry cooldowns are still a separate persisted category-key dictionary and should be treated carefully because cost-safety checks depend on it.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs, and skills-page performance remains variable.

## Completed Phase 13: Chat Metadata Save Normalization

Risk reduced: chat retry deadlines and opened-message cursor fields were sanitized on load but saved raw. Oversized reconnect timestamps, negative cursor timestamps, or overlong opened-message ids could therefore persist until the next load cleaned them.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat metadata save serialization
- Save payload validation for chat stream retry/cursor state
- Static regression coverage for raw chat metadata persistence

Behavior intentionally preserved:
- Chat rows are still not saved.
- Chat retry and next-connect deadlines still restore within the existing `CHAT_STREAM_RETRY_INTERVAL_SECONDS` cap.
- Opened-message ids still strip surrounding whitespace and cap at 64 characters, matching the load path.

Behavior intentionally removed:
- Raw chat retry deadlines and opened-message ids are no longer written directly to the save payload.
- Negative chat timestamps and oversized retry deadlines no longer survive in saved payloads.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw chat retry and opened-message id serialization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses the chat metadata helpers.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies chat timestamp clamping, retry capping, and opened-message id trimming/truncation.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The test validates helper behavior, not a physical save-file round trip.
- Chat live-stream runtime behavior remains broad and network-facing; this phase only normalizes persisted metadata.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run also printed a null texture message after the success markers.

## Completed Phase 14: Leaderboard Profile/Auth Save Normalization

Risk reduced: leaderboard profile and auth metadata were sanitized on load but saved raw. Invalid player ids, whitespace-padded refresh tokens, negative retry timestamps, overlong display names, or out-of-range avatar indexes could therefore persist until the next load cleaned them.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard score-summary save serialization
- Leaderboard profile metadata save serialization
- Leaderboard auth metadata save serialization
- Save payload validation for leaderboard profile/auth state
- Static regression coverage for raw leaderboard metadata persistence

Behavior intentionally preserved:
- Leaderboard profile claim booleans still persist through their existing fields.
- Refresh tokens are still saved, but surrounding whitespace is stripped to match restore behavior.
- Invalid player ids still become empty in the save payload and are regenerated by the existing load path.
- Avatar indexes still clamp to the configured avatar range.

Behavior intentionally removed:
- Raw negative leaderboard score/timestamp values are no longer written to the save payload.
- Raw invalid leaderboard names, name keys, player ids, avatar indexes, refresh tokens, and auth retry timestamps are no longer persisted directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw leaderboard profile/auth metadata serialization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses the leaderboard metadata helpers.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies leaderboard score-summary clamping, profile metadata sanitization, player-id sanitization, refresh-token trimming, and auth retry clamping.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase normalizes saved metadata only; it does not change leaderboard networking or name-claim flows.
- Profile claim booleans remain separate fields and can be considered for a later dedicated ownership cleanup.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run also printed the known null texture message after the success markers.

## Completed Phase 15: Hub Mission Save/Restore Normalization

Risk reduced: hub missions were normalized during runtime sync and load, but saved as the raw runtime array. Malformed mission entries, unknown action ids, passive-action missions, negative timestamps, or impossible remaining counts could therefore survive in saved data until a later load or sync cleaned them.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub mission save serialization
- Hub mission restore
- Save payload validation for mission arrays
- Static regression coverage for raw mission persistence

Behavior intentionally preserved:
- Valid unlocked, non-passive missions still save and restore.
- Mission action ids still canonicalize through the existing action helpers.
- Mission `remaining` still clamps between 1 and `target`.
- Mission assignment timestamps still clamp to nonnegative values.

Behavior intentionally removed:
- Raw malformed mission entries are no longer written directly to the save payload.
- Unknown action missions and passive-action missions are no longer preserved in saved mission arrays.
- The inline hub mission restore loop in secondary load was replaced by `_restore_hub_missions_from_save()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw hub mission save/restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_hub_missions_for_save()` and restore uses the shared mission-list normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies hub mission save normalization, malformed restore clearing, and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Leaderboard fetch retry state remains a separate persisted dictionary and has cost-safety constraints, so it needs a separate ownership review.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run also printed a null texture message from lazy detail-card unmounting after the success markers.

## Completed Phase 16: Convergence Module Save/Restore Normalization

Risk reduced: convergence module state was normalized on restore but saved as the raw runtime dictionary. Unknown module ids, malformed state entries, negative build timestamps, or negative completion counts could therefore persist in save data even though restore only accepts current build convergence actions.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Convergence module save serialization
- Convergence module restore
- Save payload validation for convergence module state
- Static regression coverage for raw convergence module persistence

Behavior intentionally preserved:
- Valid build convergence module ids still save and restore.
- `built` and `building` flags still persist as booleans.
- `build_started_unix` and `completions` still restore as nonnegative integers.
- The secondary load behavior still restores convergence modules only through the existing restore call sites.

Behavior intentionally removed:
- Raw malformed convergence module entries are no longer written directly to the save payload.
- Unknown convergence module ids are no longer preserved in saved module state.
- The inline convergence restore parser was replaced by `_normalized_convergence_modules()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw convergence module save/restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_convergence_modules_for_save()` and restore uses the shared convergence module normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies convergence module save normalization, malformed restore clearing, and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Current activity data does not appear to author convergence actions directly, so the focused test injects a synthetic convergence action into the test scene's action lookup to validate the normalizer.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 17: Hub Module Save/Restore Normalization

Risk reduced: hub module state was sanitized on restore but saved as the raw runtime dictionary. Unknown module ids, malformed module states, out-of-range levels, negative build timestamps, and derived trophy state could therefore persist in save data even though the restore path only accepts current `HUB_MODULE_DEFS` entries.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub module save serialization
- Hub module restore
- Save payload validation for hub module state
- Static regression coverage for raw hub module persistence

Behavior intentionally preserved:
- Known hub module ids from `HUB_MODULE_DEFS` still save and restore.
- Module `level` still clamps to `0..HUB_MODULE_MAX_LEVEL`.
- `building` still persists as a boolean.
- `build_started_msec` legacy data is still restored through the canonical `build_started_unix_msec` field.
- Derived trophy hub state remains excluded from direct save/restore, matching the previous restore behavior.

Behavior intentionally removed:
- Raw malformed hub module entries are no longer written directly to the save payload.
- Unknown hub module ids are no longer preserved in saved module state.
- The inline hub module restore parser was replaced by `_restore_hub_modules_from_save()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw hub module save/restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_hub_modules_for_save()` and restore uses the shared hub module normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies hub module save normalization, malformed restore clearing, legacy build timestamp handling, derived trophy exclusion, and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Leaderboard fetch retry state remains a separate persisted dictionary and has cost-safety constraints, so it needs a separate ownership review.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run printed null texture and RID initialization messages after the success markers.

## Completed Phase 18: Hub Decor Layout Save/Restore Normalization

Risk reduced: hub decor layout was repaired on restore but saved as the raw runtime array. Invalid decor types, out-of-range sprite indexes, impossible sizes, and off-field positions could therefore persist until a later load repaired or discarded them.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub decor layout save serialization
- Hub decor layout restore
- Save payload validation for decor layout entries
- Static regression coverage for raw hub decor persistence

Behavior intentionally preserved:
- Valid `tree` and `decor` entries still save and restore.
- Tree sprite indexes still clamp to `0..5`; decor sprite indexes still clamp to `0..15`.
- Decor sizes still clamp to `80..460`.
- Positions are still clamped/repositioned through the existing `_hub_find_decor_position()` collision-avoidance path.
- Non-array saved decor layout still clears the runtime layout, matching the previous restore behavior.

Behavior intentionally removed:
- Raw malformed decor entries are no longer written directly to the save payload.
- Unknown decor entry types are no longer preserved in saved decor layout.
- The inline decor restore parser was replaced by `_normalized_hub_decor_layout()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw hub decor layout serialization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_hub_decor_layout_for_save()` and restore uses the shared decor layout normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies hub decor layout save normalization, malformed restore clearing, type filtering, index clamping, size clamping, position clamping, and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Hub module positions remain a separate persisted dictionary and still need a separate ownership review.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run printed null texture and RID initialization messages from lazy detail-card mounting after the success markers.

## Completed Phase 19: Passive Module Save Normalization

Risk reduced: passive module state was normalized on restore but saved as the raw runtime dictionary. Malformed module entries, empty module ids, oversized stored values, invalid timing values, and out-of-range yield/capacity values could therefore persist in save data even though restore already repaired or skipped them.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Passive module save serialization
- Passive module restore input normalization
- Save payload validation for passive module state
- Static regression coverage for raw passive module persistence

Behavior intentionally preserved:
- Named passive module ids still save and restore without validating against action data.
- `stored`, `time_seconds`, `yield`, `capacity`, `seeded`, and `last_update` still use the existing `_passive_module_state_from_save()` rules.
- Secondary restore still honors `preserve_existing` and only adds missing module state.

Behavior intentionally removed:
- Raw malformed passive module entries are no longer written directly to the save payload.
- Empty passive module ids are no longer preserved.
- Raw out-of-range passive module values are no longer persisted directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw passive module serialization.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_passive_modules_for_save()` and passive restore uses the shared dictionary normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies passive module save normalization and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Passive module ids remain intentionally open-ended because the prior restore path accepted arbitrary named ids. A stricter source-of-truth review would need a separate progression compatibility pass.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 20: Hub Module Position Save/Restore Normalization

Risk reduced: hub module positions already used a save helper, but save and restore used separate normalization paths. Storable module ids, legacy saved dictionaries, runtime `Vector2` values, and coordinate clamping could drift if one path changed without the other.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub module position save serialization
- Hub module position restore
- Save payload validation for hub position dictionaries
- Static regression coverage for hub position normalization

Behavior intentionally preserved:
- Storable hub position ids still come from `_hub_can_store_position()`, including `trophy`.
- Runtime `Vector2` positions still save as plain `{x, y}` dictionaries.
- Saved `{x, y}` dictionaries still restore to clamped `Vector2` positions.
- Non-dictionary saved position data still clears runtime positions, matching the previous restore behavior.

Behavior intentionally removed:
- Save and restore no longer have separate hub position normalization logic.
- Unknown hub position ids are not preserved in saved payloads.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw hub module position serialization and inline restore drift.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_hub_module_positions_for_save()` and restore uses the shared position normalizer.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies hub module position save normalization, malformed restore clearing, valid-id filtering, coordinate clamping, and payload output.
- `.\scripts\check-project.ps1` passed, including the save-normalization gate and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Remaining leaderboard networking behavior should continue to be guarded by the cost-safety audit before changes.
- The test validates helper behavior and payload output, not a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 21: Leaderboard Fetch Retry Save/Restore Normalization

Risk reduced: leaderboard failure retry cooldowns protect Firebase reads from rapid retries, but the persisted dictionary was saved raw while load canonicalized keys. Stale category keys or duplicate aliases could therefore persist in save data and make the cost-safety boundary harder to reason about.

Files changed:
- `scripts/main.gd`
- `scripts/check-leaderboard-cost-safety.ps1`
- `scripts/check-project.ps1`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard fetch retry save serialization
- Leaderboard fetch retry restore
- Cost-safety validation for helper-based retry persistence
- Project validation coverage for leaderboard cost-safety

Behavior intentionally preserved:
- Read failures still update `leaderboard_fetch_retry_unix_by_category[valid_id]` immediately.
- Fetch checks still use the max of successful fetch and failed fetch timestamps before auth work.
- Successful fetch timestamps still reset on launch because leaderboard rows are not saved.
- Retry cooldowns still persist across relaunches.

Behavior intentionally removed:
- Raw unknown leaderboard fetch retry category keys are no longer preserved in saved data.
- Duplicate category keys that canonicalize to the same category now keep the highest retry timestamp, preserving the more conservative cooldown.
- The standard project check now includes the leaderboard cost-safety audit, so this path is covered by the normal validation gate.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw leaderboard fetch retry serialization and raw restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_leaderboard_fetch_retry_unix_by_category_for_save()` and the standard project check runs the leaderboard cost-safety gate.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed. It now verifies helper-based fetch retry persistence, helper-based auth retry persistence, and helper-based chat cooldown persistence.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies leaderboard fetch retry save normalization, malformed restore clearing, duplicate canonical category handling, and payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase does not change leaderboard networking, auth, Firebase rules, or row parsing.
- Save-normalization coverage still validates helper behavior and payload output rather than a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs. The latest run printed null texture messages from lazy detail-card mounting after the success markers.

## Completed Phase 22: Achievement Toast Seen-ID Save/Restore Normalization

Risk reduced: achievement toast seen state is a set-like dictionary, but the save payload wrote the raw runtime dictionary. False entries, empty ids, and malformed values could therefore persist even though only truthy seen ids matter.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Achievement toast seen-id save serialization
- Achievement toast seen-id restore
- Save payload validation for set-like seen state
- Static regression coverage for raw seen-id persistence

Behavior intentionally preserved:
- Non-empty truthy ids still save and restore as `true`.
- Non-string ids are still stringified for compatibility.
- Non-dictionary saved seen-id data still clears the runtime set.

Behavior intentionally removed:
- False seen-id entries are no longer written directly to the save payload.
- Empty seen ids are no longer preserved.
- The inline achievement toast restore parser was replaced by `_normalized_achievement_toast_seen_ids()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw achievement toast seen-id serialization and raw restore tokens.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_achievement_toast_seen_ids_for_save()` and restore uses the shared seen-id normalizer.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies achievement toast seen-id save normalization, malformed restore clearing, truthy-id filtering, and payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase does not validate seen ids against currently defined achievements, preserving compatibility with past or future achievement ids.
- Save-normalization coverage still validates helper behavior and payload output rather than a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 23: Scalar Progression Metadata Save Normalization

Risk reduced: several save fields were clamped on restore but written raw in `_save_payload()`. That split ownership between "save whatever runtime has" and "fix it later on load", which makes corrupted counters/timers easier to persist and harder to reason about.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub selected-module serialization
- Hub mission cooldown serialization
- Ad bonus timer serialization
- Activity/onboarding progress counter serialization
- Stamina tip hold timer serialization
- Music flow timer/heat serialization
- Static guards against raw scalar progression metadata persistence

Behavior intentionally preserved:
- Valid persisted hub module selections still save as-is.
- Derived/invalid hub selections still resolve to `pond`, matching existing restore behavior.
- Hub cooldowns, ad bonus time, activity counters, onboarding counters, stamina tip hold seconds, and music flow values keep the same bounds already enforced by restore.
- No gameplay rules, timers, rewards, or UI flows were changed.

Behavior intentionally removed:
- Negative cooldown/counter/timer values are no longer written to the save payload.
- Over-cap ad bonus seconds, guaranteed-success completions, stamina tip hold seconds, and music flow heat are no longer written to the save payload.
- Derived hub selection `trophy` is no longer written as a selected hub module because restore already rejects it and falls back to `pond`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw scalar progression metadata serialization for the normalized fields.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses the scalar normalization helpers and the focused save test covers them.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies scalar helper behavior and final payload output for the normalized fields.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase does not normalize larger raw save dictionaries such as `skills`, `stamina`, or `stamina_bank`; those are more gameplay-critical and need separate inspection.
- Save-normalization coverage still validates helper behavior and payload output rather than a physical save-file round trip.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs, including null texture messages from lazy detail-card mounting after the success markers.

## Completed Phase 24: Fishing Numeric Save Normalization

Risk reduced: fishing wallet/net/boat numeric state was clamped on restore but written raw in `_save_payload()`. A transient negative or over-threshold fishing value could therefore persist until a later reload fixed it.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing currency save serialization
- Fishing net stored fish/success/XP/mastery serialization
- Fishing boat stored fish/success/XP/mastery serialization
- Save-normalization coverage for fishing numeric payload fields
- Static audit coverage for raw fishing numeric persistence

Behavior intentionally preserved:
- Fishing currency still cannot restore below zero.
- Net stored fish still caps at `FISHING_NET_HAUL_THRESHOLD - 1`.
- Boat stored fish still caps at `FISHING_BOAT_HAUL_THRESHOLD - 1`.
- Net/boat success counts, stored XP, and stored mastery still clamp to zero minimum.
- Equipment/tool compatibility and fishing unlock behavior were not changed.

Behavior intentionally removed:
- Negative fishing currency, success counts, stored XP, or stored mastery are no longer written to the save payload.
- Over-threshold net/boat stored fish counts are no longer written to the save payload.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw fishing numeric state serialization for the normalized fields.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses fishing numeric normalization helpers and the focused save test covers them.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed. It now verifies fishing numeric helper behavior and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally leaves `equipped_fishing_tool_id` compatibility behavior alone; tool restore has additional unlock reconciliation that deserves a separate review.
- This phase does not normalize the larger `skills`, `stamina`, or `stamina_bank` dictionaries.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 25: Action Progress Save/Restore Normalization

Risk reduced: `action_progress` was saved and restored as a raw float, while runtime action processing and offline simulation treat progress as a bounded in-flight fraction. A corrupted value above completion or below zero could therefore enter runtime before the next action-processing clamp.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Active action progress save serialization
- Active action progress restore
- Crash-session action progress reporting
- Save-normalization test setup for `_load_game_core()` restore checks
- Static audit coverage for raw `action_progress` persistence/restore

Behavior intentionally preserved:
- In-progress actions still restore with their saved progress.
- Progress can still approach completion but is capped at `0.999`, matching the existing offline/runtime convention that restored progress should not cross completion by itself.
- Negative progress still behaves as zero progress.
- Running action identity normalization remains unchanged.

Behavior intentionally removed:
- Raw negative action progress is no longer saved or restored.
- Raw `>= 1.0` action progress is no longer saved, restored, or reported in crash-session payloads.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `action_progress` save and restore paths.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_action_progress_for_save()` and `_load_game_core()` uses `_normalized_action_progress()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies action progress save helper behavior, restore normalization, and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase does not validate selected/running skill ids beyond the existing running action canonicalization.
- This phase does not normalize the larger `skills`, `stamina`, or `stamina_bank` dictionaries.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 26: Stamina Save Normalization

Risk reduced: stamina was persisted through two raw dictionaries, `stamina` and `stamina_bank`. Runtime treats the bank as a derived regen-progress representation of fractional stamina, but raw saves could preserve unknown skill ids, over-max values, negative values, and bank values that disagreed with the stamina fraction.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Stamina save serialization
- Stamina bank save serialization
- Save payload validation for duplicated stamina progress state
- Static audit coverage for raw stamina persistence

Behavior intentionally preserved:
- Stamina still restores through the existing compatibility path, including legacy integer-stamina plus bank conversion.
- Known skills still save stamina values.
- Stamina values still clamp to `0.._max_stamina(skill_id)`.
- Fractional stamina still preserves regen progress through `stamina_bank`.

Behavior intentionally removed:
- Unknown skill ids are no longer written to saved stamina dictionaries.
- Negative or over-max stamina is no longer written to the save payload.
- Full-stamina skills no longer persist nonzero bank values.
- Saved `stamina_bank` is now derived from the normalized stamina fraction instead of raw duplicate state.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `stamina` and `stamina_bank` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_stamina_for_save()` and `_stamina_bank_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies stamina helper behavior and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally leaves the restore compatibility logic intact; old saves can still use integer stamina plus bank to recover partial regen progress.
- Skill XP/level payload normalization remains separate and still needs careful review.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 27: Skill XP/Level Save Normalization

Risk reduced: skill state was written as the raw runtime `skills` dictionary even though load only restores known skill ids, only reads XP, and recalculates levels afterward. A stale runtime `level`, unknown skill id, malformed skill entry, or negative XP could therefore be persisted even though level is intended to be derived from XP.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Skill save serialization
- Skill level derivation
- Save payload validation for XP-derived levels
- Static audit coverage for raw skill persistence

Behavior intentionally preserved:
- Known skills still save their XP.
- Skill levels still follow the existing `_xp_for_level()` curve and cap at 99.
- Runtime level recalculation still updates `skills[skill_id]["level"]` from XP.
- Save restore compatibility remains unchanged; old saves still load XP from known skill dictionaries and recalculate levels.

Behavior intentionally removed:
- Unknown skill ids are no longer written in the saved `skills` dictionary.
- Malformed skill states are no longer written raw; they save as XP 0, level 1 for known skills.
- Negative XP is no longer written to the save payload.
- Stale runtime `level` values are no longer persisted when they disagree with XP.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `skills` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_skills_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies skill helper behavior and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally leaves the restore compatibility logic intact; loaded XP normalization is still minimal and follows the existing load contract.
- Manual unlock and mastery systems remain the authoritative unlock/progression detail stores beyond skill XP totals.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs, including occasional null texture messages after success markers.

## Completed Phase 28: Active Skill Identity Save Normalization

Risk reduced: `selected_skill_id` and `running_skill_id` were saved raw while `running_action_id` was already normalized. That allowed half-valid active-action state, such as a known running skill with no valid running action, or an unknown selected skill id, to persist until later validation repaired it.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Selected skill save serialization
- Running skill save serialization
- Save payload validation for active skill/action identity
- Static audit coverage for raw active skill id persistence

Behavior intentionally preserved:
- Known selected skills still save as-is.
- Valid running skill/action pairs still save and keep action alias canonicalization.
- Unknown selected skill ids fall back to the same default skill family used by validation (`fight` when available).
- Invalid running actions still result in no saved running action.

Behavior intentionally removed:
- Unknown selected skill ids are no longer written to the save payload.
- Unknown running skill ids are no longer written to the save payload.
- A running skill id is no longer saved unless the running action also resolves to a valid canonical action.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `selected_skill_id` and `running_skill_id` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_selected_skill_id_for_save()` and `_running_skill_id_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies selected/running skill helper behavior and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally leaves load-time selected/running skill compatibility behavior intact.
- `current_screen` and other navigation/UI state are not persisted, so this phase only covers the saved skill identity fields.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 29: Resource And Audio Scalar Save Normalization

Risk reduced: `log_currency`, `music_volume`, and `sfx_volume` were clamped on load or by UI setters but still written raw in `_save_payload()`. A transient negative log count or out-of-range volume value could therefore persist until a future reload repaired it.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Log currency save serialization
- Music volume save serialization
- SFX volume save serialization
- Save payload validation for resource/audio scalar bounds
- Static audit coverage for raw resource/audio persistence

Behavior intentionally preserved:
- Logs still restore with a zero minimum.
- Music and SFX volume still restore within `0.0..1.0`.
- Audio version migration still resets old saves to default volumes before bus application.
- Runtime sliders and audio bus behavior were not changed.

Behavior intentionally removed:
- Negative log currency is no longer written to the save payload.
- Out-of-range music and SFX volumes are no longer written to the save payload.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `log_currency`, `music_volume`, and `sfx_volume` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses the resource/audio scalar helpers.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies resource/audio helper behavior and final payload output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase does not touch boolean settings such as mute/offline/god-mode flags; those preserve their existing compatibility behavior.
- `last_result` remains raw player-facing status text and may deserve separate review for save-file noise.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 30: Obsolete Global Mute Save Field Removal

Risk reduced: `is_muted` was a stale global mute field saved alongside the real `music_muted` and `sfx_muted` settings. Load no longer restored it into behavior and reset the runtime variable to `false`, so keeping it in saves made audio ownership look split across three mute sources.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Audio settings save serialization
- Save payload validation for obsolete audio fields
- Static audit coverage for ignored global mute persistence

Behavior intentionally preserved:
- Music mute and SFX mute remain the persisted audio mute settings.
- Audio volume and mute bus application is unchanged.
- Old saves with `is_muted` are still harmless because the load path did not use that field for behavior.

Behavior intentionally removed:
- The obsolete `is_muted` runtime variable was removed.
- `_save_payload()` no longer writes `is_muted`.
- The load path no longer performs a no-op reset of `is_muted`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects saving obsolete `is_muted` state.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` does not include `is_muted`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies the save payload omits `is_muted`.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally does not alter `music_muted` or `sfx_muted`; those remain the real audio mute state.
- `last_result` remains raw player-facing status text and may deserve separate review for save-file noise.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 31: God Mode Enabled Save Normalization

Risk reduced: `god_mode_enabled` was saved raw even though load gates it through `_god_mode_available()`. In release-bound builds `_god_mode_available()` is intentionally false, so a raw enabled flag could persist state that load immediately disables. The separate `god_mode_save_tainted` audit marker remains intentionally preserved.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- God mode active-toggle save serialization
- Save payload validation for release-gated god-mode state
- Static audit coverage for raw god-mode enabled persistence

Behavior intentionally preserved:
- God mode remains unavailable in release-bound builds because `_god_mode_available()` returns false.
- Loading old saves still gates `god_mode_enabled` by `_god_mode_available()`.
- `god_mode_save_tainted` still persists as the audit marker for saves that have ever used test-only controls.

Behavior intentionally removed:
- Raw `god_mode_enabled = true` is no longer written to the save payload when god mode is unavailable.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `god_mode_enabled` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_god_mode_enabled_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies god-mode enabled is availability-gated while taint remains saved.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally does not clear or reinterpret `god_mode_save_tainted`; that marker is preserved by design.
- Other boolean settings such as `offline_progress_enabled`, `music_muted`, and `sfx_muted` remain raw because they are already boolean settings rather than derived availability-gated state.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 32: Fishing Net Collection Legacy Save Field Removal

Risk reduced: new saves still wrote both canonical `fishing_net_collect_completed` and legacy `fishing_net_collected`, even though restore already accepts the legacy key as a fallback. Keeping both made fishing net collection ownership look split across two save fields.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing net collection save serialization
- Legacy save-field compatibility boundary
- Save payload validation for canonical fishing net collection state
- Static audit coverage for duplicate fishing net collection persistence

Behavior intentionally preserved:
- New saves still persist net collection through `fishing_net_collect_completed`.
- Old saves with only `fishing_net_collected` still restore correctly through the existing fallback.
- Runtime `fishing_net_collected` behavior and offer availability are unchanged.

Behavior intentionally removed:
- New saves no longer write the legacy duplicate `fishing_net_collected` field.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects saving legacy `fishing_net_collected`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` writes canonical `fishing_net_collect_completed` and omits legacy `fishing_net_collected`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies canonical save and legacy restore fallback.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase intentionally keeps legacy restore fallback so old saves remain compatible.
- Other fishing tool/equipment compatibility fields still need separate review.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 33: Equipped Fishing Tool Save Normalization

Risk reduced: `_save_payload()` wrote raw `equipped_fishing_tool_id` while load repaired invalid, locked, or stale rod-slot ids through fishing unlock reconciliation. That made save and restore disagree about who owns the canonical equipped-tool value, and a bad runtime tool id could be preserved into a future compatibility path.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Equipped fishing tool save serialization
- Fishing rod upgrade save compatibility
- Static audit coverage for raw fishing equipment persistence
- Save-normalization coverage for invalid equipped-tool ids

Behavior intentionally preserved:
- Valid equipped tools still save as the selected tool.
- Stale rod-slot ids save as the highest currently collected rod, matching the existing restore canonicalization.
- Old saves that only imply fishing unlocks through `equipped_fishing_tool_id` still restore and reconcile collected tool state.

Behavior intentionally removed:
- New saves no longer preserve invalid or locked equipped fishing tool ids; they save `hands` instead.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw `equipped_fishing_tool_id` payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_equipped_fishing_tool_id_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies rod-slot canonicalization, invalid-tool fallback, payload output, and legacy equipped-tool restore.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Individual fishing tool collection booleans still save directly because they are the current ownership state for unlocks.
- Load-time equipped-tool compatibility remains intentionally broad so old saves can still unlock tools from historical equipped ids.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 34: Fishing Rod Collection Hierarchy Normalization

Risk reduced: fishing rod progression is hierarchical, but save data could write `fishing_rod_collected`, `fishing_reinforced_rod_collected`, and `fishing_star_rod_collected` as independent booleans. Contradictory saves, such as star rod collected without earlier rod flags, could make offer visibility and unlock checks disagree about progression.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing rod upgrade save serialization
- Fishing rod upgrade restore reconciliation
- Static audit coverage for raw rod collection persistence
- Save-normalization coverage for impossible rod hierarchy states

Behavior intentionally preserved:
- Collecting the base rod, reinforced rod, and star rod still follows the existing progression order.
- Valid rod collection states save as before.
- Old saves still load, but contradictory old rod flags are repaired into the intended hierarchy.

Behavior intentionally removed:
- New saves no longer write impossible rod hierarchy states.
- Legacy saves with upgraded rods but missing prerequisite rod flags no longer keep that contradictory runtime shape after restore.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw rod collection payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses rod collection save helpers and restore calls `_reconcile_fishing_rod_collection_state()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies star-rod save normalization, contradictory legacy restore repair, and reinforced-rod prerequisite repair.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Non-rod fishing tool unlock booleans (`fishing_boat_built`, `fishing_mirror_collected`, and net collection) remain direct source-of-truth flags.
- Load-time equipped-tool compatibility remains broad by design so historical saves can still infer collected tools from equipped ids.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 35: Chat Opened Cursor Restore Normalization

Risk reduced: chat read-cursor sanitation was split between save helpers and inline restore code. The timestamp clamp and message-id trimming both define whether the unread dot treats older chat rows as already seen, so duplicated normalization could drift across future chat patches.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat opened/read cursor restore
- Chat opened message-id normalization
- Static audit coverage for raw chat cursor save/restore paths
- Save-normalization coverage for chat cursor save and restore symmetry

Behavior intentionally preserved:
- Saved chat opened timestamps are still clamped to zero or greater.
- Saved and restored chat opened message ids are still stripped and capped at 64 characters.
- Chat rows themselves remain unsaved; the realtime stream is still reopened only when the chat strip is visible.

Behavior intentionally removed:
- The secondary load path no longer has its own inline copy of chat opened cursor sanitation.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw chat opened timestamp persistence and duplicate inline chat cursor restore code.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses both chat cursor save helpers and secondary restore uses `_restore_chat_opened_cursor_from_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies chat opened cursor save and restore sanitation through the shared helper.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Chat stream retry and next-connect restore still clamp inline because they depend on current time and separate retry semantics.
- Chat unread behavior still depends on realtime rows arriving after launch; this phase only normalizes the persisted read cursor.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 36: Leaderboard Profile Claim Save Normalization

Risk reduced: `_save_payload()` still wrote `leaderboard_profile_claimed` and `leaderboard_name_claim_verified` as independent raw booleans even though restore repairs invalid combinations. A save could claim a profile with a guest/default name, an invalid or missing name key, or an unverified claim, leaving save and load to disagree about the valid ownership state.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard profile claim save serialization
- Leaderboard name-key save derivation
- Static audit coverage for raw profile claim persistence
- Save-normalization coverage for valid, guest, and unverified profile claim states

Behavior intentionally preserved:
- Valid verified profile claims still save as claimed and verified.
- Missing name keys for valid verified claims are still derived from the display name, matching existing restore behavior.
- Guest/default names and unverified claims still behave as unclaimed profiles.

Behavior intentionally removed:
- New saves no longer persist claimed/verified profile booleans when the saved profile state would be cleared by restore.
- New saves no longer preserve stray name keys for unclaimed, guest, default, or invalid profile states.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw leaderboard profile claim boolean payload writes.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_save_payload()` uses `_leaderboard_profile_claimed_for_save()` and `_leaderboard_name_claim_verified_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies unverified claims clear, verified claims derive a missing name key, and guest names do not persist as claimed profiles.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The restore path still contains inline profile repair logic; this phase intentionally normalized save output first without changing load compatibility.
- Leaderboard submit readiness still depends on live auth/Firebase state outside save normalization.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 37: Leaderboard Profile Restore Helper Extraction

Risk reduced: leaderboard profile repair was still inline in the secondary restore path after save serialization became canonical. Guest/default name repair, missing name-key derivation, and unverified claim clearing were therefore owned partly by save helpers and partly by a long restore block.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard profile metadata restore
- Leaderboard profile claim reconciliation
- Static audit coverage for duplicate inline profile restore logic
- Save-normalization coverage for profile save and restore symmetry

Behavior intentionally preserved:
- Default display names still become guest names on restore.
- Guest names still clear profile claim state.
- Valid verified claims with missing name keys still derive the key from the display name.
- Unverified claims still clear claimed state and stored name keys.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of leaderboard profile metadata repair.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline leaderboard profile restore assignments outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_leaderboard_profile_metadata_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies profile save and restore behavior for valid, guest, and unverified claim states.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Leaderboard submit readiness still depends on live auth/Firebase state outside save normalization.
- `_leaderboard_profile_claim_valid()` still lazily derives a name key during live checks; that runtime mutation may deserve a separate review.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 38: Leaderboard Auth Restore Helper Extraction

Risk reduced: durable leaderboard auth state and volatile session state were restored inline in the secondary load path. That made it easy for future changes to blur which auth fields are trusted from saves: refresh token and retry cooldown are durable, while ID token, expiry, and provider are runtime-only/reset state.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard auth metadata restore
- Auth save/restore ownership boundary
- Static audit coverage for duplicate inline auth restore logic
- Save-normalization coverage for volatile auth reset behavior

Behavior intentionally preserved:
- Refresh tokens still restore after trimming whitespace.
- Auth retry cooldowns still restore with a zero minimum.
- ID tokens and token expiry still reset on load.
- The ignored auth provider still resets to `anonymous` and is not read from save data.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of leaderboard auth metadata restore.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline leaderboard auth restore assignments outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_leaderboard_auth_metadata_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies auth restore clears volatile ID token/expiry, trims refresh token, clamps retry cooldown, and resets provider.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Leaderboard auth request/refresh behavior still depends on live Firebase responses outside save normalization.
- Auth failure handling can still clear refresh tokens at runtime; that behavior was intentionally not changed.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 39: Chat Stream Retry Restore Helper Extraction

Risk reduced: chat stream retry cooldowns were saved through helpers but restored inline in the secondary load path. The restore logic also carries the legacy `chat_fetch_retry_unix` fallback, caps future retry values, and keeps next-connect at least the retry timestamp, so duplicating that policy made chat reconnect timing easy to drift.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat stream retry metadata restore
- Legacy chat retry fallback handling
- Static audit coverage for duplicate inline chat retry restore logic
- Save-normalization coverage for chat retry save/restore symmetry

Behavior intentionally preserved:
- `chat_stream_retry_unix` still restores from the canonical key, falling back to legacy `chat_fetch_retry_unix`.
- Restored retry timestamps are still clamped between zero and `now + CHAT_STREAM_RETRY_INTERVAL_SECONDS`.
- `chat_stream_next_connect_unix` still cannot precede the restored retry timestamp and is capped to the same maximum.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of chat stream retry restore logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline chat retry restore assignments outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_chat_stream_retry_metadata_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies capped retry restore, next-connect ordering, and legacy `chat_fetch_retry_unix` fallback.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Live chat reconnect behavior still depends on Firebase/auth availability and runtime polling outside save normalization.
- This phase intentionally leaves chat last-send restore inline because it is a single scalar clamp and has not shown duplicated ownership yet.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 40: Chat Last-Send Restore Helper Extraction

Risk reduced: chat send throttle state was saved through `_chat_last_send_unix_for_save()` but restored inline beside the other chat metadata helpers. That split made future chat cooldown changes easy to apply to save or restore, but not both.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat last-send cooldown restore
- Chat metadata save/restore ownership boundary
- Static audit coverage for duplicate inline last-send restore logic
- Save-normalization coverage for last-send restore clamping

Behavior intentionally preserved:
- `chat_last_send_unix` still saves and restores with a zero minimum.
- Nonnegative chat last-send timestamps still restore unchanged.
- Chat send throttling still uses `_chat_next_send_seconds()` unchanged.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of chat last-send restore logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline chat last-send restore assignments outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_chat_last_send_unix_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies last-send restore clamps negative timestamps and preserves nonnegative timestamps.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Live chat send throttling still depends on runtime send success/failure and auth state outside save normalization.
- Chat pending-send draft recovery remains separate from this cooldown metadata.
- `check-project.ps1` still prints known Godot dummy-renderer/shutdown leak noise after successful runs.

## Completed Phase 41: Hub Selected Module Restore Helper Extraction

Risk reduced: selected hub module save state already serialized through `_hub_selected_module_id_for_save()`, but restore still had the fallback rule inline in `_load_game_secondary_restore()`. That made hub navigation recovery depend on a large load function remembering the same valid-module boundary as save.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub selected-module save/restore ownership
- Secondary save restore flow
- Static audit coverage for duplicate inline selected-module restore logic
- Save-normalization coverage for selected-module restore fallback behavior

Behavior intentionally preserved:
- Valid persisted hub module ids still restore unchanged.
- Unknown or derived selected hub module ids still fall back to `pond`.
- Save payload normalization still mirrors the same fallback rule.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of selected hub module fallback logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline selected hub module restore assignments outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_hub_selected_module_id_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies valid selected hub modules restore unchanged and unknown selections fall back to `pond`.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Hub module availability still depends on the broader `HUB_MODULE_DEFS` registry and hub module restore order.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 42: Activity Progress Counter Restore Helper Extraction

Risk reduced: activity start/completion counts and guaranteed-success completions were saved through clamping helpers, but restore kept their normalization inline in `_load_game_secondary_restore()`. The riskiest part was that missing guaranteed-success completions intentionally default from the already-restored completion count, making restore order an implicit rule inside a large function.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity progress counter restore
- Guaranteed-success completion fallback ownership
- Core and secondary guaranteed-success restore normalization
- Secondary save restore flow
- Static audit coverage for duplicate inline activity counter restore logic
- Save-normalization coverage for counter restore clamping and fallback behavior

Behavior intentionally preserved:
- Negative activity start and completion counts still restore as zero.
- Guaranteed-success completions still clamp to `GUARANTEED_SUCCESS_ACTION_COMPLETIONS`.
- Saves missing `guaranteed_success_action_completions` still default from the restored activity completion count.

Behavior intentionally removed:
- The secondary load path no longer owns an inline copy of activity progress counter restore logic.
- The core load path no longer owns a separate inline copy of guaranteed-success completion clamping.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline activity counter and guaranteed-success restore assignments outside the shared helpers.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_activity_progress_counts_from_save(data)` and core restore uses `_restore_guaranteed_success_action_completions_from_save(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies counter clamping, valid count preservation, guaranteed-success fallback from restored completions, and direct fallback use by the shared guaranteed-success helper.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Onboarding starter action counts and tutorial repair flags still restore immediately after this helper and remain inline because they have additional tutorial-state dependencies.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 43: Timed Scalar Restore Helper Extraction

Risk reduced: hub mission cooldown and ad bonus remaining seconds were saved through bounded helpers, but restored inline in `_load_game_secondary_restore()`. These timers affect visible wait state and bonus multipliers, so save/load drift could create confusing mission waits or overlong/negative bonus time.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub mission cooldown restore
- Ad bonus timer restore
- Secondary save restore flow
- Static audit coverage for duplicate inline timer restore logic
- Save-normalization coverage for timer restore bounds

Behavior intentionally preserved:
- Hub mission cooldown timestamps still restore with a zero minimum.
- Ad bonus remaining seconds still restore between zero and `AD_BONUS_MAX_SECONDS`.
- Valid nonnegative cooldowns and valid bonus seconds still restore unchanged.

Behavior intentionally removed:
- The secondary load path no longer owns inline copies of hub mission cooldown and ad bonus timer restore logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline hub mission cooldown and ad bonus timer restore assignments outside the shared helpers.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_hub_mission_cooldown_until_unix_from_save(data)` and `_restore_ad_bonus_seconds_remaining_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies hub mission cooldown restore bounds and ad bonus restore clamping/capping/preservation.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Hub mission scheduling still depends on runtime mission slot state after restore.
- Ad bonus countdown still depends on offline progress and runtime decrement paths outside this save/load helper.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 44: Stamina Tip and Music Flow Restore Helper Extraction

Risk reduced: stamina-tip discovery hold time and music-flow state were saved through bounded helpers, but restored inline in `_load_game_secondary_restore()`. Music flow also mixed saved state with an unsaved action counter reset, making it easy for future changes to accidentally preserve or reset the wrong field.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Stamina gauge pre-tip hold restore
- Music flow heat/active-seconds restore
- Music start-chance unlock restore
- Secondary save restore flow
- Static audit coverage for duplicate inline stamina-tip and music-flow restore logic
- Save-normalization coverage for music-flow restore defaults and unsaved counter reset

Behavior intentionally preserved:
- Stamina-tip hold seconds still restore between zero and `STAMINA_TIP_DISCOVERY_HOLD_SECONDS`.
- Music flow heat still restores between zero and 36.0.
- Music flow active seconds still clamp to zero minimum.
- Missing music-flow heat and active-seconds keys still preserve the current in-memory defaults.
- `flow_actions_taken` still resets to zero on load because it is not persisted.

Behavior intentionally removed:
- The secondary load path no longer owns inline copies of stamina-tip hold and music-flow restore logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline stamina-tip and music-flow restore assignments outside the shared helpers.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_stamina_gauge_pre_tip_hold_seconds_from_save(data)` and `_restore_music_flow_state_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies stamina-tip restore bounds, music-flow heat and active-seconds bounds, missing-key defaults, unlock restoration, and unsaved flow action counter reset.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The post-load groove-floor unlock repair still runs after secondary restore and remains separate from raw music-flow metadata.
- Runtime music-flow decay, completion triggers, and lockout behavior remain outside this save/load helper.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 45: Leaderboard Submission Restore Helper Extraction

Risk reduced: leaderboard last-submitted score metadata was saved through helper-backed clamps, but restored inline in `_load_game_secondary_restore()`. Category scores also had save-only duplicate-category merging, so restore could treat malformed or legacy category aliases differently from save.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard submission metadata restore
- Leaderboard submitted category score normalization
- Secondary save restore flow
- Static audit coverage for duplicate inline leaderboard submission restore logic
- Save-normalization coverage for malformed category scores and legacy total-XP fallback

Behavior intentionally preserved:
- Last submitted score and submit timestamps still restore with a zero minimum.
- Missing `leaderboard_last_submitted_total_xp` still defaults from the restored last submitted score.
- Unknown leaderboard category ids still canonicalize through `_leaderboard_valid_category_id()`.

Behavior intentionally removed:
- The secondary load path no longer owns inline copies of leaderboard submission restore logic.
- Restore no longer allows a lower duplicate canonical category score to overwrite a higher score; save and restore now both keep the max.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline leaderboard submission and category-score restore logic outside the shared helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_leaderboard_submission_metadata_from_save(data)` and save uses `_normalized_leaderboard_last_submitted_scores(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies leaderboard submission scalar restore clamping, malformed category score clearing, legacy total-XP fallback, category canonicalization, negative category clamping, and duplicate canonical category max merging.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Live leaderboard submission and retry behavior still depends on Firebase/auth state outside this save/load metadata helper.
- Leaderboard profile/avatar/player-id restore remains separate because it has profile-claim and id-generation rules.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 46: Leaderboard Profile Identity Restore Consolidation

Risk reduced: leaderboard display-name and claim metadata restored through `_restore_leaderboard_profile_metadata_from_save()`, but avatar index and player id restored inline in `_load_game_secondary_restore()`. That split made leaderboard profile identity easy to update in one place while forgetting the adjacent avatar/player-id sanitization and regeneration rules.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard profile identity restore
- Leaderboard avatar index normalization
- Leaderboard player-id sanitization and regeneration
- Secondary save restore flow
- Static audit coverage for duplicate inline leaderboard avatar/player-id restore logic
- Save-normalization coverage for avatar clamp, invalid player-id regeneration, and valid player-id preservation

Behavior intentionally preserved:
- Leaderboard avatar indexes still restore through `_valid_profile_avatar_index()`.
- Invalid or empty saved player ids still sanitize to empty and regenerate through `_make_leaderboard_player_id()`.
- Valid saved player ids still restore unchanged.
- Display-name, name-key, claim, and verification reconciliation remains unchanged.

Behavior intentionally removed:
- The secondary load path no longer owns inline copies of leaderboard avatar and player-id restore logic.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline leaderboard avatar/player-id restore logic outside the shared profile helper.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_leaderboard_profile_metadata_from_save(data)` and that the helper owns avatar normalization, player-id sanitization, and missing-id regeneration.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies avatar index clamping, invalid player-id regeneration, and valid player-id preservation through the profile restore helper.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Live leaderboard writes still depend on Firebase/auth state and may update player/avatar rows outside save restore.
- Leaderboard auth token restore remains separate from profile identity because it intentionally clears volatile token state.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 47: Leaderboard Fetch Metadata Restore Helper Extraction

Risk reduced: leaderboard successful fetch timestamps intentionally reset on launch, while retry cooldowns restore from save. That volatile-vs-persisted boundary was encoded inline in `_load_game_secondary_restore()`, making it easy to accidentally start saving success timestamps or clearing retry cooldowns during future leaderboard work.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Leaderboard successful fetch timestamp restore/reset
- Leaderboard fetch retry cooldown restore
- Secondary save restore flow
- Static audit coverage for duplicate inline leaderboard fetch metadata restore logic
- Save-normalization coverage for volatile success fetch clearing and persisted retry restore

Behavior intentionally preserved:
- `leaderboard_fetch_unix_by_category` still clears on launch because successful fetch rows are not persisted.
- `leaderboard_fetch_retry_unix_by_category` still restores through the existing normalizer.
- Retry cooldown categories still canonicalize and duplicate canonical categories still keep the highest cooldown.

Behavior intentionally removed:
- The secondary load path no longer owns inline copies of leaderboard successful-fetch clearing and retry restore sequencing.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects extra inline successful-fetch timestamp clears outside reset paths and `_restore_leaderboard_fetch_metadata_from_save()`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_leaderboard_fetch_metadata_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies successful fetch timestamps clear on restore while retry cooldowns restore and canonicalize.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Runtime leaderboard fetch success/failure updates still depend on Firebase/network behavior outside save restore.
- Retry cooldown policy still lives in the runtime fetch paths; this helper only owns persisted metadata restore.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 48: Tip Metadata Restore Helper Extraction

Risk reduced: lock-click, passive-module, and silver-opportunity tip metadata restored inline in both core and secondary load. The silver-opportunity action key was also restored with a direct canonicalization call while save used `_action_key_for_save()`, leaving small duplicated paths for tutorial tip persistence.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Tip metadata restore
- Silver opportunity action-key restore normalization
- Core and secondary save restore flow
- Static audit coverage for duplicate inline tip metadata restore logic
- Save-normalization coverage for tip flag restore and malformed silver action-key clearing

Behavior intentionally preserved:
- Lock-click, passive-module, and silver-opportunity tip seen flags still restore from booleans.
- Silver-opportunity action keys still canonicalize saved fishing aliases.
- Malformed, passive, or unknown action keys still restore as empty through the shared action-key normalizer.

Behavior intentionally removed:
- Core and secondary load no longer own duplicate inline tip metadata restore blocks.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline tip metadata and silver action-key restore logic outside `_restore_tip_metadata_from_save()`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts boot-render and secondary restore use `_restore_tip_metadata_from_save(data)`, and that the helper uses `_action_key_for_save()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies tip flag restore, silver-opportunity action-key alias canonicalization, and malformed key clearing.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The larger onboarding/tutorial repair block remains inline because it has ordered tutorial-state dependencies.
- Runtime tip display and dismissal behavior remains outside this save/load helper.
- Other scalar secondary restore fields still remain inline and should be extracted only when each helper can be pinned with focused tests.

## Completed Phase 49: Activity Crit Restore Helper Extraction

Risk reduced: activity crit and mega-crit completion flags restored inline in `_load_game_secondary_restore()`, including the rule that mega-crit implies regular crit. That dependency is easy to lose if future achievement or toast work edits one flag without noticing the other.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity crit metadata restore
- Activity mega-crit implication rule
- Secondary save restore flow
- Static audit coverage for duplicate inline activity crit restore logic
- Save-normalization coverage for crit/mega-crit restore consistency

Behavior intentionally preserved:
- `activity_crit_seen` still restores from the saved boolean.
- `activity_mega_crit_seen` still restores from the saved boolean.
- A save with mega-crit seen still forces regular crit seen.

Behavior intentionally removed:
- The secondary load path no longer owns the inline activity mega-crit-implies-crit rule.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline activity crit restore logic outside `_restore_activity_crit_metadata_from_save()`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_activity_crit_metadata_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies mega-crit restore forces regular crit seen and that unseen crit flags remain unset.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Achievement toast backfill still runs immediately before this helper and remains separate because it depends on whether the save contained `achievement_toast_seen_ids`.
- Runtime activity crit/mega-crit detection remains outside this save/load helper.
- The larger onboarding/tutorial repair block remains inline because it has ordered tutorial-state dependencies.

## Completed Phase 50: Boot-Visible Tip Flag Restore Helper Extraction

Risk reduced: activity-start and hub tutorial tip flags restored in both the boot-render save-field path and secondary restore path. That duplicated early-vs-final restore logic could make initial UI render disagree with the final restored state if one path changed later.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Boot-visible tip flag restore
- Activity-start tip seen restore
- Hub tutorial tip seen restore
- Boot-render and secondary save restore flow
- Static audit coverage for duplicate inline boot-visible tip restore logic
- Save-normalization coverage for present and omitted boot-visible tip flags

Behavior intentionally preserved:
- `activity_start_tip_seen` still restores from the saved boolean and defaults to false.
- `hub_tutorial_tip_seen` still restores from the saved boolean and defaults to false.
- Both the early boot-render path and secondary restore still see the same values.

Behavior intentionally removed:
- Boot-render and secondary restore no longer own separate inline copies of these two tip-flag assignments.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects duplicate inline activity-start and hub tutorial tip restore logic outside `_restore_boot_visible_tip_flags_from_save()`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts both boot-render and secondary restore use `_restore_boot_visible_tip_flags_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies boot-visible tip flags restore from saved booleans and default to false when omitted.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The larger onboarding/tutorial repair block remains inline because it has ordered tutorial-state dependencies.
- Runtime tip display and dismissal behavior remains outside this save/load helper.
- Build-resource plank boost persistence is tracked separately in Phase 51.

## Completed Phase 51: Plank Boost Restore Helper Extraction

Risk reduced: the build plank boost toggle was saved directly from runtime state and restored inline in the large secondary load path. That made a small persisted build-resource flag another reason to edit the fragile restore block and gave save/load no shared ownership boundary.

Files changed:
- `scripts/main.gd`
- `scripts/audit-activity-database.ps1`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Plank boost save state
- Plank boost secondary restore
- Static audit coverage for duplicate inline plank boost persistence logic
- Save-normalization coverage for present and omitted plank boost save state

Behavior intentionally preserved:
- `plank_boost_enabled` still saves and restores as a boolean.
- Saves with plank boost enabled still restore it enabled.
- Saves without the field still default plank boost to disabled.
- Runtime build resource behavior is unchanged.

Behavior intentionally removed:
- The save payload no longer serializes the raw plank boost variable directly.
- The secondary load path no longer owns the inline plank boost assignment.

Validation:
- `.\scripts\audit-activity-database.ps1` passed. It now rejects raw plank boost save payload entries and duplicate inline restore assignments outside `_restore_plank_boost_enabled_from_save()`.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the save payload uses `_plank_boost_enabled_for_save()` and secondary restore uses `_restore_plank_boost_enabled_from_save(data)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies plank boost saves enabled state, restores enabled state, and defaults missing save data to disabled.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Runtime plank boost toggling and button visual refresh remain outside this persistence helper.
- The larger onboarding/tutorial repair block remains inline because it has ordered tutorial-state dependencies.

## Completed Phase 52: Onboarding Progression Restore Helper Extraction

Risk reduced: the secondary save restore path still owned a long ordered onboarding/tutorial repair block. That made unrelated save fixes easy to entangle with tutorial compatibility rules and made it unclear which system owned legacy onboarding implications.

Files changed:
- `scripts/main.gd`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Secondary onboarding progression restore
- Legacy onboarding compatibility backfills
- Swipe navigation/tip implication restore
- Fight tutorial reveal implication restore
- Save-normalization coverage for onboarding repair rules

Behavior intentionally preserved:
- Starter completion count still clamps to zero on save and restore.
- Existing saves that showed the auto-run message still backfill one starter completion.
- Existing saves with two starter completions still reveal the header when summary is not yet revealed.
- Existing saves with `skill_swipe_tip_seen` still unlock swipe eligibility/navigation and fight reveal state.
- Existing saves with the medal tip shown still dismiss the mastery tip.

Behavior intentionally removed:
- `_load_game_secondary_restore()` no longer owns inline onboarding progression repair assignments.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts secondary restore uses `_restore_onboarding_progression_from_save(data)` and does not own the inline starter-completion repair assignment.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies the onboarding auto-run backfill, header reveal backfill, swipe-tip implication, fight reveal implication, and medal/mastery-tip implication.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Boot-render restore still reads a smaller subset of onboarding flags for early first paint.
- Runtime onboarding sequence scheduling and UI tip positioning remain outside this persistence helper.

## Completed Phase 53: Shared Onboarding Completion Implications

Risk reduced: boot-render restore and final onboarding restore both carried the same compatibility rule that restored tutorial/tip completion should imply fight tutorial reveal state and swipe unlock state. Keeping that rule duplicated made first paint and final restored state easier to drift apart.

Files changed:
- `scripts/main.gd`
- `scripts/test-save-normalization.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Boot-render onboarding implication restore
- Final onboarding progression implication restore
- Shared onboarding completion predicate
- Save-normalization coverage for shared completion implications

Behavior intentionally preserved:
- Restored stamina tip, swipe tip, explore tip, or tutorial completion still reveals the fight tutorial state.
- Restored tutorial completion or seen swipe tip still unlocks swipe eligibility/navigation.
- Stamina tip restoration alone still does not unlock swipe navigation.
- The richer final onboarding repair rules for partial fight reveal state and zero-stamina swipe unlocks remain in `_restore_onboarding_progression_from_save()`.

Behavior intentionally removed:
- Boot-render and final onboarding restore no longer own separate inline copies of the completion implication rules.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts both boot-render restore and final onboarding progression restore use `_apply_onboarding_restored_completion_implications()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output. It now verifies shared completion implications reveal fight tutorial state from restored stamina tips and do not unlock swipe navigation from stamina tips alone.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Boot-render restore still directly reads the subset of onboarding fields needed for early first paint.
- Runtime onboarding sequence scheduling and UI tip positioning remain outside the persistence helpers.
- The full project check still emits existing Godot shutdown/resource warnings and a dummy texture warning from lazy detail mounting, tracked separately from this save-restore cleanup.

## Completed Phase 54: Action Card Background Texture Fallback

Risk reduced: lazy action-card mounting could build a card background with a cached null texture after threaded prewarm failed or a background path was unavailable. Under the headless/dummy renderer this surfaced as a texture warning when the lazy-mounted card entered the tree.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Action-card background texture ownership
- Lazy card mount safety
- Static performance guard coverage for nullable background textures

Behavior intentionally preserved:
- Valid action background art is still used when available.
- Missing action background art still falls back to the existing transparent fallback texture and the rounded background's fallback color.
- The optional simple background branch remains behind `ACTION_CARD_SIMPLE_BACKGROUND_ENABLED`.
- Action art fallback texture caching remains unchanged.

Behavior intentionally removed:
- `_action_card_background()` no longer assigns `_texture(action.bg)` directly to visual nodes.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts action-card backgrounds normalize missing textures before creating visual nodes and do not assign possibly-null background textures directly.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate. The prior `Parameter "t" is null` lazy-mount warning did not reappear in this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Passive-module, fishing-area, and other specialized card backgrounds still have their own texture paths and fallbacks.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 55: Shared Visual Texture Fallback Boundary

Risk reduced: texture loading correctly returns `null` for missing assets, but several UI image factories still had to remember to convert that nullable loader result into a safe visual texture. That made texture-backed controls inconsistent and left future UI patches likely to reintroduce nullable visual assignments.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Visual texture fallback ownership
- General image helper texture assignment
- Action art image texture assignment
- Action-card background texture assignment
- Static performance guard coverage for nullable visual textures

Behavior intentionally preserved:
- `_texture(path)` remains a nullable asset loader/cache API.
- Valid textures still render when available.
- Missing visual textures still render as the existing transparent fallback.
- Action-card backgrounds still use the same fallback-color behavior when art is missing.

Behavior intentionally removed:
- `_image()`, `_image_from_texture()`, `_action_art_image()`, and `_action_card_background_texture()` no longer each own separate nullable-texture handling.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts general images, optional texture images, action art, and action-card backgrounds use the shared visual fallback boundary instead of assigning nullable loaded textures directly.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate. The prior `Parameter "t" is null` lazy-mount warning still did not reappear.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Specialized atlas/profile texture constructors can still receive null source textures and should be audited separately before broader changes.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 56: Atlas Visual Texture Fallback Boundary

Risk reduced: the shared visual fallback covered direct image loads, but atlas-backed visual paths could still hand a `TextureRect` a null spritesheet texture or create an avatar atlas with a null source sheet. That left specialized visual builders with a different texture-safety rule than the common image helpers.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Spritesheet visual texture fallback ownership
- Hub sheet image fallback handling
- Profile avatar atlas source fallback handling
- Thieving trophy/heist spritesheet visual assignment
- Static performance guard coverage for atlas-backed visual fallbacks

Behavior intentionally preserved:
- Valid spritesheet and profile avatar atlas textures still render from their source art.
- Missing spritesheet/profile source art now uses the shared transparent visual fallback before reaching visible controls.
- `_spritesheet_texture()` and `_atlas_texture()` remain nullable low-level asset APIs.

Behavior intentionally removed:
- Hub/trophy/heist/profile visual constructors no longer assign nullable atlas results directly to visible texture controls.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts spritesheet visual textures, hub sheet images, and profile avatar atlas textures use the shared visual fallback boundary when atlas loading fails.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate. The prior `Parameter "t" is null` lazy-mount warning did not reappear.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct `_texture(...)` assignments outside the common image/atlas helpers still exist and should be audited by feature area before broad changes.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 57: Thieving Jail Bar Visual Fallback

Risk reduced: thieving heist cards now use safe fallback handling for their background and trophy art, but both heist and action jail overlays still assigned the jail-bars texture directly from the nullable loader. That left one visual path in the same card family with different texture-safety behavior.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Thieving heist jail overlay texture assignment
- Thieving action jail overlay texture assignment
- Static performance guard coverage for thieving jail-bar visuals

Behavior intentionally preserved:
- Valid jail-bar art still renders normally.
- Missing jail-bar art now uses the shared transparent visual fallback rather than a null texture.
- Jail overlay layout, input handling, countdown labels, and shake animations are unchanged.

Behavior intentionally removed:
- Thieving jail overlays no longer assign `_texture(THIEVING_HEIST_JAIL_BARS_TEXTURE)` directly to `TextureRect`s.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts both thieving heist and thieving action jail overlays use `_texture_or_visual_fallback(THIEVING_HEIST_JAIL_BARS_TEXTURE)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and skills page performance gate. The prior `Parameter "t" is null` lazy-mount warning did not reappear.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct `_texture(...)` assignments outside the thieving jail overlay remain and should be audited by feature area.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 58: Fishing Background Visual Fallback

Risk reduced: fishing area and offer cards still assigned rounded background textures directly from the nullable loader while their foreground tool art already used the shared visual fallback. That left one feature family with mixed texture ownership rules and made future fishing UI edits more fragile.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing area card background texture assignment
- Fishing method tile background texture assignment
- Fishing net/rod/mirror/upgrade/boat offer background texture assignment
- Ordered visual texture fallback for the net offer's preferred beach background
- Static performance guard coverage for fishing visual fallback use

Behavior intentionally preserved:
- Valid fishing background art still renders normally.
- The net offer still prefers `beach-rocky-zoom.png` and falls back to the tide-pool background before using the transparent visual fallback.
- Fishing card layout, unlocks, costs, tool art, method tiles, and fluid strip behavior are unchanged.

Behavior intentionally removed:
- Fishing area and offer card backgrounds no longer assign nullable `_texture(...)` results directly to visible controls.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing area, method tile, and offer backgrounds use the shared visual fallback boundary, and that the net offer preserves ordered fallback.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output after fixing an indentation parse error in the fishing method tile art block.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct `_texture(...)` assignments outside the fishing background feature area remain and should be audited by feature area.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 59: Passive Module Background Visual Fallback

Risk reduced: passive woodcutting module cards still assigned their rounded background texture directly from the nullable loader while regular action cards and fishing cards now use the shared visual fallback boundary. That left passive activity cards with a different texture ownership rule, so missing or renamed background art could reach a visible control as `null`.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Passive module card background texture assignment
- Visual fallback ownership for activity-card-like surfaces
- Static performance guard coverage for passive module card backgrounds

Behavior intentionally preserved:
- Valid passive module background art still renders normally.
- Passive module layout, interactivity, loot rendering, shade overlay, and woodcutting progression behavior are unchanged.
- Missing passive module background art still uses the existing transparent visual fallback plus the rounded background's fallback color.

Behavior intentionally removed:
- Passive module card backgrounds no longer assign nullable `_texture(...)` results directly to visible controls.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts passive module card backgrounds use `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Direct nullable texture assignments remain in other visible UI surfaces and should be audited by feature family rather than mass-rewritten.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 60: Hub Mission Visual Fallback

Risk reduced: hub mission board visuals still assigned textures directly from the nullable loader even though the surrounding activity and hub image helpers now use the shared visual fallback boundary. Missing board art, mission task art, or the paper badge could therefore reach visible `TextureRect`s as `null`, leaving the mission-board feature family with different texture ownership rules.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub mission board background art assignment
- Hub mission task action-art assignment
- Hub mission paper badge texture assignment
- Static performance guard coverage for hub mission visible textures

Behavior intentionally preserved:
- Valid hub mission board art, task art, and paper badge art still render normally.
- Mission board layout, navigation, task selection, badge positioning, and text behavior are unchanged.
- Missing hub mission visual art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- Hub mission board/task/badge `TextureRect`s no longer assign nullable `_texture(...)` results directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts hub mission board art, task art, and paper badge art use `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct nullable texture assignments remain in boot/home/achievement/icon surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 61: Launch And Home Intro Visual Fallback

Risk reduced: the launch warmup splash and home hero scene still assigned visible `TextureRect` art directly from the nullable loader. These first-screen visuals now follow the same shared non-null visual fallback boundary as activity cards, fishing cards, passive module cards, and hub mission visuals.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Boot warmup splash texture assignment
- Home hero character texture assignment
- Home hero speech-bubble texture assignment
- Static performance guard coverage for launch/home intro visuals

Behavior intentionally preserved:
- Valid launch splash, hero, and speech-bubble art still render normally.
- Boot warmup overlay layout, progress text, reveal/hide timing, home hero anchors, and hero message behavior are unchanged.
- Missing launch/home intro art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- Launch/home intro `TextureRect`s no longer assign nullable `_texture(...)` results directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the boot warmup splash, home hero art, and home speech bubble use `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The intermittent `Parameter "t" is null` warning reappeared from the existing skill-detail shelf shadow update path during this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The intermittent skill-detail shelf shadow `Parameter "t" is null` warning should be isolated in a separate phase; it appears to come from `_update_skill_detail_shadow()` / `_set_canvas_item_modulate_if_changed()` rather than launch/home texture assignment.
- Other direct nullable texture assignments remain in achievement, icon-button, and hub trophy surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 62: Hidden Skill-Detail Shadow Update Guard

Risk reduced: the full project check intermittently logged `Parameter "t" is null` from `_update_skill_detail_shadow()` while the skill-detail shelf shadow was being updated. The path hid the custom shadow overlay at zero alpha but still wrote `modulate` afterward, leaving a small hidden-CanvasItem update race in the high-frequency skill UI loop.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Skill-detail shelf shadow visibility/update flow
- High-frequency skill detail UI update guardrails
- Static performance guard coverage for hidden shelf-shadow updates

Behavior intentionally preserved:
- Visible shelf shadow fade behavior is unchanged.
- The shadow still becomes visible when alpha rises above the existing `0.001` threshold.
- Skill detail scrolling, jump arrows, swipe previews, and header gauge refresh behavior are unchanged.

Behavior intentionally removed:
- The hidden shelf shadow no longer receives redundant `modulate` writes after it has been made invisible.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the shelf shadow uses one visibility threshold and returns before modulate writes while hidden.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The prior `Parameter "t" is null` shelf-shadow warning did not reappear on this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The warning was intermittent, so future full-check runs should keep watching for `Parameter "t" is null` before treating this path as fully retired.
- Other direct nullable texture assignments remain in achievement, icon-button, and hub trophy surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 63: Featured Achievement Art Fallback

Risk reduced: the home achievements page created the featured activity image through the safe image helper, but `_update_most_impressive_activity()` later overwrote it with a direct nullable `_texture(...)` result. That split ownership between safe construction and unsafe refresh, so a missing or renamed achievement activity art path could still leave the visible featured art with a null texture.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Featured achievement activity art refresh
- Home achievement visual fallback ownership
- Static performance guard coverage for most-impressive activity art

Behavior intentionally preserved:
- Valid featured achievement activity art still renders normally.
- Featured achievement card visibility, featured name text, medal texture, and home achievement refresh scheduling are unchanged.
- Missing featured achievement activity art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- `_update_most_impressive_activity()` no longer assigns a nullable `_texture(...)` result directly to the featured achievement art `TextureRect`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts most-impressive activity art uses `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The prior `Parameter "t" is null` shelf-shadow warning did not reappear on this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct nullable texture assignments remain in icon-button, hub trophy, jump-arrow, plank-button, and passive-log surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 64: Hub Trophy Platform Visual Fallback

Risk reduced: the hub trophy display already used the shared spritesheet visual fallback for the trophy itself, but the platform underneath still assigned a direct nullable `_texture(...)` result. That left one visible hub trophy surface with a different texture ownership rule than the trophy art above it.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub trophy platform texture assignment
- Hub trophy display visual fallback ownership
- Static performance guard coverage for hub trophy visuals

Behavior intentionally preserved:
- Valid hub trophy platform art still renders normally.
- Trophy button placement, depth ordering, click/input handling, and best-trophy spritesheet art are unchanged.
- Missing hub trophy platform art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- The hub trophy platform `TextureRect` no longer assigns a nullable `_texture(...)` result directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the hub trophy platform uses `_texture_or_visual_fallback(...)` and trophy art keeps its spritesheet visual fallback.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. A `Parameter "t" is null` warning appeared from action-card lazy mounting / medal texture setup during this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The action-card medal texture path should be isolated in a separate phase because the full project check surfaced `Parameter "t" is null` during lazy card mounting.
- Other direct nullable texture assignments remain in icon-button, jump-arrow, plank-button, and passive-log surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 65: Visible Mastery Medal Fallback

Risk reduced: `_mastery_medal_texture()` correctly returned `null` when the medal sheet was unavailable, but visible action-card medals and achievement medals assigned that nullable result directly. The full project check surfaced `Parameter "t" is null` during lazy action-card mounting, pointing at this visible medal texture boundary.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Visible action-card medal texture assignment
- Animated medal ceremony texture assignment
- Featured achievement medal texture assignment
- Achievement medal slot mastery texture assignment
- Static performance guard coverage for visible mastery medal fallbacks

Behavior intentionally preserved:
- Valid mastery medal art still renders normally from `MASTERY_MEDALS_TEXTURE`.
- Hidden/no-medal action-card state still uses `null` texture when mastery level is zero.
- Medal placement, animation timing, replacement fall animation, featured achievement card text, and achievement slot state logic are unchanged.
- `_mastery_medal_texture()` remains nullable for callers that can safely handle missing medal-sheet art.

Behavior intentionally removed:
- Visible mastery medal `TextureRect`s no longer assign nullable `_mastery_medal_texture(...)` results directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts visible mastery medal paths use `_mastery_medal_visual_texture(...)`, and that the wrapper falls back to `_visual_fallback_texture()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The prior lazy-mount medal `Parameter "t" is null` warning did not reappear on this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct nullable texture assignments remain in icon-button, jump-arrow, plank-button, and passive-log surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 66: Shared Button Icon Visual Fallback

Risk reduced: shared button factories still assigned button and settings-page icon textures directly from the nullable loader. A missing or renamed icon path could therefore leave visible nav, utility, or settings buttons with null icon textures, even though surrounding image helpers now use the shared visual fallback boundary.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Generic square icon button texture assignment
- Deferred nav icon hydration
- Immediate nav icon assignment
- Settings page icon row texture assignment
- Static performance guard coverage for shared button icon fallbacks

Behavior intentionally preserved:
- Valid button icons still render normally.
- Deferred nav icon loading behavior is unchanged except for the non-null fallback on hydration.
- Button sizing, icon alignment, nav pop animation, settings row layout, and button input behavior are unchanged.
- Missing button icon art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- Shared button/icon helpers no longer assign nullable `_texture(...)` results directly to visible button icons or icon `TextureRect`s.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_icon_button()`, `_ensure_nav_bar_icons()`, `_nav_button()`, and `_settings_page_button()` use `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Direct nullable texture assignments remain in specialized back-arrow, jump-arrow, plank-button, and lock-piece surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 67: Skill Navigation Arrow Visual Fallback

Risk reduced: the skill-detail back arrow and scroll jump arrows still assigned textures directly from the nullable loader. These are visible navigation controls that run during skill page setup and high-frequency scroll UI, so missing arrow art should follow the same non-null visual fallback boundary as the broader button/icon helpers.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity back-arrow texture assignment
- Skill detail jump-arrow texture assignment
- Static performance guard coverage for skill navigation arrow fallbacks

Behavior intentionally preserved:
- Valid back-arrow and jump-arrow art still renders normally.
- Back button sizing, tint, label, placement, visibility sync, jump-arrow hover/hold fade, disabled state, and scroll behavior are unchanged.
- Missing navigation arrow art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- Skill navigation arrow controls no longer assign nullable `_texture(...)` results directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_add_activity_back_arrow()` and `_activity_jump_button()` use `_texture_or_visual_fallback(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Direct nullable texture assignments remain in the passive plank button and lock-piece surfaces and should be reviewed by feature family.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 68: Passive Plank Button Icon Fallback

Risk reduced: the passive woodcutting module card had already moved its background art to the shared visual fallback boundary, but its plank boost button still assigned a nullable icon texture directly. A missing plank icon could therefore leave the visible boost button without a safe texture while the rest of the passive card followed the non-null visual rule.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Passive plank boost button icon assignment
- Passive module card visual fallback ownership
- Static performance guard coverage for plank boost icon fallback

Behavior intentionally preserved:
- Valid plank icon art still renders normally.
- Plank boost button sizing, position, tooltip, style, input behavior, and boost state sync are unchanged.
- Missing plank icon art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- The passive plank boost button no longer assigns a nullable `_texture(...)` result directly to `Button.icon`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_build_passive_module_card()` uses `_texture_or_visual_fallback(PLANK_ICON_TEXTURE)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The activity lock-piece helper is the remaining direct visible `_texture(...)` assignment in this scan and should be reviewed next with its padlock/chain compatibility paths.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 69: Activity Lock Piece Visual Fallback

Risk reduced: the activity lock-piece helper was the final direct visible `_texture(...)` assignment in the current nullable texture scan. Missing lock-piece art could therefore leave a visible `TextureRect` with a null texture while the rest of the shared image/button surfaces used the visual fallback boundary. The lock rig's chain/padlock setup and cropped padlock image pipeline remain separate compatibility owners because they intentionally allow nulls for hit-image and pulse-texture degradation.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity lock-piece texture assignment
- Visible lock-piece fallback ownership
- Static performance guard coverage for activity lock-piece fallbacks

Behavior intentionally preserved:
- Valid lock-piece art still renders normally.
- Activity lock overlay creation, lock rig setup, chain texture ownership, cropped padlock texture ownership, padlock hit-image compatibility, pulse texture compatibility, unlock ceremony, input routing, and SFX behavior are unchanged.
- Missing lock-piece art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- `_activity_lock_piece()` no longer assigns nullable `_texture(...)` results directly to visible `TextureRect`s.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_activity_lock_piece()` uses `_texture_or_visual_fallback(path)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Broader nullable loader use remains where it is not directly assigned to visible texture surfaces or where a compatibility owner intentionally handles nulls, including `_texture(...)`, fishing tool icon texture lookup, padlock crop helpers, and boot warmup preload registration.
- The current direct visible texture assignment scan is clear for `_texture(...)` and related button/icon texture assignments.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 70: Fishing Tool Icon Visual Fallback

Risk reduced: fishing tool icon lookup fed several visible surfaces, including the fish circle, floating wallet, tool popup rows, tool offer cards, and active fishing tool animation, but the shared helper still returned nullable `_texture(...)` values. That meant each caller had to tolerate missing art differently, and future fishing UI patches could accidentally reintroduce blank tool visuals.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing tool icon texture lookup
- Fishing wallet and active-tool visual fallback ownership
- Static performance guard coverage for fishing tool icon fallbacks

Behavior intentionally preserved:
- Valid fishing tool art still renders normally.
- Tool id aliases such as `line`, `reinforced_rod`, `star_rod`, `tool:hands`, and `tool:bamboo-rod` still resolve through the existing canonical icon mapping.
- Fish circle layout, wallet menu layout, active-tool sizing, active-tool animation, popup selection behavior, and tool offer behavior are unchanged.
- Missing fishing tool icon art now uses the existing transparent visual fallback from the shared helper.

Behavior intentionally removed:
- `_fishing_tool_icon_texture()` no longer returns nullable `_texture(...)` results directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_fishing_tool_icon_texture()` uses `_texture_or_visual_fallback(...)` and does not return `_texture(...)` directly.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Fishing location thumbnail lookup still returns a nullable loaded texture and should be reviewed separately because it has its own location-path source-of-truth mapping.
- Broader nullable loader use remains in compatibility or non-visible boundaries such as padlock crop helpers and boot warmup preload registration.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 71: Fishing Location Thumbnail Visual Fallback

Risk reduced: fishing location tiles used a single helper for thumbnail texture lookup, but that helper still returned a nullable `_texture(...)` result. A missing or renamed location thumbnail could therefore leave visible method tiles with blank art even though fishing area backgrounds and tool icons now use the shared visual fallback boundary.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing location thumbnail texture lookup
- Fishing method tile thumbnail fallback ownership
- Static performance guard coverage for location thumbnail fallbacks

Behavior intentionally preserved:
- Fishing location thumbnail path mapping is unchanged.
- Valid thumbnail art still renders normally.
- Fishing method tile layout, unlock state tinting, lock overlay behavior, mastery progress, and button behavior are unchanged.
- Missing location thumbnail art now uses the existing transparent visual fallback.

Behavior intentionally removed:
- `_fishing_location_thumbnail_texture()` no longer returns a nullable `_texture(...)` result directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_fishing_location_thumbnail_texture()` uses `_texture_or_visual_fallback(_fishing_location_thumbnail_path(area_id, location_id))`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The first full run exited 0 but emitted a transient dummy-renderer backtrace in `_update_skill_detail_shadow()`; an immediate rerun passed without that backtrace.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Broader nullable loader use remains in compatibility or non-visible boundaries such as padlock crop helpers and boot warmup preload registration.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 72: Shared UI Setter Live-Node Guards

Risk reduced: shared UI property setters guarded repeated visibility, modulate, and disabled-state writes, but still allowed writes to nodes that were already queued for deletion. These helpers are used by high-frequency skill menu, action card, fishing, and skill-detail shadow updates, so stale-node writes could produce intermittent renderer warnings or make unrelated UI patches sensitive to timing.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Shared CanvasItem visibility write guard
- Shared CanvasItem modulate write guard
- Shared BaseButton disabled-state write guard
- Skill-detail shelf-shadow update live-node boundary
- Static performance guard coverage for queued-for-deletion checks

Behavior intentionally preserved:
- Live nodes still receive visibility, modulate, and disabled-state updates exactly when their value changes.
- Skill menu card tinting, activity rails, action card feedback, fishing UI visibility, skill-detail shadow fade behavior, and button disabled behavior are unchanged for valid nodes.
- The skill-detail shelf shadow still skips hidden modulate writes and now re-checks the overlay after visibility changes before reading/writing modulate.

Behavior intentionally removed:
- Shared UI setters no longer write to CanvasItems or BaseButtons that are queued for deletion.
- The skill-detail shelf shadow no longer reads or writes overlay modulate after the visibility write if the overlay is no longer a live tree node.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the shared setters skip queued-for-deletion nodes and that `_update_skill_detail_shadow()` re-checks the overlay before reading modulate after the visibility write.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The prior transient shelf-shadow `Parameter "t" is null` backtrace did not repeat in this run.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- This phase hardens stale-node writes but does not remove the broader Godot shutdown/resource warnings still emitted by the full project check.
- Other high-frequency setters outside the shared helper boundary may still write directly and should be reviewed by subsystem when they surface in validation or profiling.

## Completed Phase 73: Action Stop-Hold Circle Guarded UI Writes

Risk reduced: the action cancel hold indicator is driven from `_process_action_stop_hold()` and wrote visibility/modulate state directly while also updating position/progress during pointer-hold input. That left a high-frequency UI path outside the shared live-node guard boundary added for the skill-detail shadow and menu/action-card updates.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Action stop-hold circle show/hide visibility ownership
- Action stop-hold circle show modulate ownership
- Action stop-hold circle queued-for-deletion checks before position/progress writes
- Static performance guard coverage for stop-hold circle guarded writes

Behavior intentionally preserved:
- The action stop-hold arming delay, press feedback, progress ring, unload animation, release/cancel behavior, and stop-running-action timing are unchanged.
- Live stop-hold circles still become visible, reset to white, move with the pointer, and reset progress exactly as before.
- Newly created stop-hold circles still start hidden before being added to the stop-hold layer.

Behavior intentionally removed:
- The stop-hold circle no longer writes `visible` or `modulate` directly in show/hide paths.
- Position/progress updates now skip stop-hold circle nodes that are queued for deletion.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts stop-hold show/hide use the shared guarded setters and sync skips queued-for-deletion nodes.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other high-frequency direct UI writes remain in hub hold circles, swipe covers, tutorial overlays, fishing active-tool layers, and modal overlays; these should be reviewed one subsystem at a time to avoid mixing behavior changes.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 74: Hub Hotspot Hold Circle Guarded UI Writes

Risk reduced: the hub module long-press move indicator is driven by `_process_hub_hotspot_hold()` and `_sync_hub_hotspot_hold_circle()`, but its visible state was still written directly. That left the hub drag/hold ring outside the shared live-node guard boundary used by the skill-detail shadow, action stop-hold circle, and other high-frequency UI paths.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub hotspot hold-circle visibility ownership
- Hub hotspot hold-circle queued-for-deletion checks before ring sync
- Static performance guard coverage for hub hotspot hold-circle guarded writes

Behavior intentionally preserved:
- Hub module press, long-press delay, drag arming, drag start, ring position, ring size, ring color, and progress timing are unchanged.
- Live hub hotspot hold circles still become visible after the existing show delay and reset to hidden/progress zero when the hold clears.
- Newly created hub hotspot hold circles still start hidden before being added to the hold layer.

Behavior intentionally removed:
- The hub hotspot hold circle no longer writes `visible` directly in sync/hide paths.
- Ring sync now skips hotspot hold-circle nodes that are queued for deletion.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts hub hotspot hold-circle sync uses the shared guarded visibility setter and skips queued-for-deletion nodes.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` exited successfully and covered the save-normalization and skills page performance gates. Two full runs also repeated an unrelated dummy-renderer `Parameter "t" is null` backtrace from lazy action-card construction (`_build_detail_interactive_action_card()` via `_detail_lazy_settle_warm_mount()`), so that should be isolated in a separate phase before treating full validation output as clean.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Lazy action-card construction can still emit intermittent dummy-renderer texture allocation backtraces during settle-warm mounting; this appears unrelated to the hub hold-circle path and should be reviewed separately.
- Other high-frequency direct UI writes remain in swipe covers, tutorial overlays, fishing active-tool layers, and modal overlays; these should be reviewed one subsystem at a time.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 75: Detail Card Style Resource Prewarm

Risk reduced: lazy action-card construction owned first-time creation of procedural detail-card StyleBoxTexture resources for stat chips. Under headless dummy rendering, full validation repeatedly logged `Parameter "t" is null` from `_build_detail_interactive_action_card()` while `_detail_lazy_settle_warm_mount()` was constructing cards. Moving those style allocations into the explicit detail-card prewarm boundary keeps lazy mounting focused on node assembly instead of renderer texture initialization.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Detail action-card style resource ownership
- Stat-box StyleBoxTexture first-use allocation
- Lazy settle-warm mount resource boundary
- Static performance guard coverage for detail-card style prewarm

Behavior intentionally preserved:
- Action stat boxes still use the same textured paper-button styles, active/inactive outlines, pressed variants, action-art frame style, action-art border style, and locked-card shade style.
- Lazy card slot creation, settle-warm mount budget, card order, scroll behavior, and skills page performance thresholds are unchanged.
- Texture path prewarm still owns action/background asset preloading; this phase only adds procedural style resource prewarm beside it.

Behavior intentionally removed:
- Lazy settle-warm mounting no longer owns first-time procedural detail-card style texture allocation.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts detail-card style resources are prewarmed and that texture/lazy-mount queue boundaries call the prewarm helper.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The repeated lazy action-card `Parameter "t" is null` backtrace did not recur after this change.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other procedural `ImageTexture.create_from_image(...)` caches still exist and should be reviewed only when they surface in validation or profiling, because many are one-time UI assets with separate ownership.
- Other high-frequency direct UI writes remain in swipe covers, tutorial overlays, fishing active-tool layers, and modal overlays; these should be reviewed one subsystem at a time.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 76: Fishing Active Tool Guarded Visibility

Risk reduced: fishing active-tool visibility is updated from `_update_fishing_active_tool_animation()` every fishing area frame, while `_sync_fishing_active_tool_hit()` mirrors that visibility to the invisible hit button. Both paths wrote `visible` directly, leaving an active gameplay UI loop outside the shared guarded setter boundary used by other high-frequency UI updates.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing active-tool layer visibility ownership
- Fishing active-tool hit-button visibility ownership
- Static performance guard coverage for fishing active-tool visibility writes

Behavior intentionally preserved:
- Active fishing tool visibility still follows whether the current area card owns the running action.
- Tool positioning, rotation, scale, initialization animation, net/rod/boat/mirror animation behavior, hit button size, hit button mouse filtering, and press behavior are unchanged.
- Inactive tools still reset to the same base position, rotation, and scale.

Behavior intentionally removed:
- Fishing active-tool layer and hit-button sync no longer write `visible` directly in the per-frame update path.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing active-tool animation and hit sync use `_set_canvas_item_visible_if_changed(...)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other high-frequency direct UI writes remain in swipe covers, tutorial overlays, modal overlays, and some fishing offer/status surfaces; these should be reviewed one subsystem at a time.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 77: Fishing Method Art Tint Guard

Risk reduced: fishing method slot updates reset the method art panel tint to white on every fishing area update. That write sits in the same per-frame fishing method loop as method sway/camera updates, so it bypassed the shared guarded modulate setter even when the tint was already correct.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing method slot art-panel tint ownership
- Static performance guard coverage for fishing method tint resets

Behavior intentionally preserved:
- Fishing method art panels still reset to white during method slot updates.
- Method sway, location camera zoom/pan, mastery medal updates, mastery progress, attempt bars, and area selection sync are unchanged.
- Construction-time art tint defaults and non-fishing action-card tint paths are unchanged.

Behavior intentionally removed:
- Fishing method slot updates no longer assign `art_panel.modulate = Color.WHITE` directly each update.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_update_fishing_method_slot()` uses `_set_canvas_item_modulate_if_changed(art_panel, Color.WHITE)`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other high-frequency direct UI writes remain in swipe covers, tutorial overlays, modal overlays, fishing offer/status surfaces, and fishing method animation transforms. Animation transform writes are intentionally direct and should only be guarded where they are idempotent state resets.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 78: Fishing Area Warning Visibility Guard

Risk reduced: fishing area selection synced warning text and then directly toggled the warning stat box visibility from that text. The selection path can be called from the fishing area update loop when running/selection state changes, so this idempotent visibility write belonged behind the shared guarded setter instead of assigning `visible` directly.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing area warning-box visibility ownership
- Static performance guard coverage for fishing area warning visibility

Behavior intentionally preserved:
- Fishing area warning text, XP/yield stat text, warning title behavior, selection sync keys, border color, and selected action ownership are unchanged.
- The warning box still appears only when warning text is non-empty.

Behavior intentionally removed:
- Fishing area selection no longer assigns `warning_box.visible` directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `_apply_fishing_area_selection()` uses `_set_canvas_item_visible_if_changed(warning_box, not warning_text.is_empty())`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other high-frequency direct UI writes remain in swipe covers, tutorial overlays, modal overlays, fishing offer/status surfaces, and intentional animation transforms.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 79: Fishing Method Button Disabled Guard

Risk reduced: fishing method unlock lifecycle code directly toggled `method_button.disabled` when enabling a method after its unlock ceremony and disabling it during the ceremony. Those writes were lifecycle-owned, but they bypassed the shared guarded button setter and one path could still touch a queued-for-deletion button while fishing detail cards were being refreshed or torn down.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing method button enable/disable ownership
- Static performance guard coverage for fishing method unlock button state

Behavior intentionally preserved:
- Fishing method buttons still become clickable after unlock ceremony finalization.
- Fishing method buttons are still disabled during the unlock ceremony.
- Mouse filtering, pressed-signal connection, default button SFX attachment, lock animation, and detail refresh behavior are unchanged.

Behavior intentionally removed:
- Fishing method unlock lifecycle no longer assigns `method_button.disabled` directly.
- `_activate_fishing_method_button()` no longer touches queued-for-deletion method buttons.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing method activation and unlock ceremony disable writes use `_set_base_button_disabled_if_changed()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Other direct fishing offer/status UI writes remain, including one-time construction tints and animation alpha writes that need separate inspection before any guard conversion.
- Wider swipe-cover, tutorial-overlay, and modal-overlay visibility/modulate paths still contain intentionally animated direct writes mixed with idempotent state resets.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 80: Fishing Offer Collapse Guard

Risk reduced: fishing offer collection transitions disabled the tapped source button directly, then used a delayed tween callback to hide the collapsed offer root by instance id. That path is intentionally animation-owned, but the final button/visibility state writes were idempotent lifecycle writes and could run after the source/root had entered deletion during a detail refresh.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing offer collected-transition state ownership
- Bound control hiding after delayed tween callbacks
- Static performance guard coverage for fishing offer collapse state writes

Behavior intentionally preserved:
- Collected fishing offers still ignore input immediately, fade out, shrink their module height, and hide after the collapse transition.
- Net, rod, rod upgrade, boat, and mirror reward/currency/save flows are unchanged.
- Wallet fly-to-target animation timing, fade timing, and height tween timing are unchanged.

Behavior intentionally removed:
- Fishing offer collection no longer assigns source button `disabled` directly.
- Bound hide callbacks no longer assign `control.visible = false` directly.
- Offer transition callbacks now skip queued-for-deletion source/root controls.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing offer collection uses guarded button disabling, queued-for-deletion checks, and guarded bound hiding.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Fishing offer construction still contains direct one-time tint assignments for affordability state; those should be inspected separately before any consolidation.
- Fishing area stat fades and method attempt-bar alpha writes are still animation/state blends and need targeted review before converting any of them to guarded setters.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 81: Fishing Offer Affordability Tint Source

Risk reduced: fishing rod, mirror, rod-upgrade, and boat offer builders each repeated the same unavailable-art tint literal and inline affordability tint rule. Those offer cards are built from separate functions, so future changes to offer visual affordance could drift between tools.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Fishing offer affordability art tint ownership
- Static performance guard coverage for offer builder tint ownership

Behavior intentionally preserved:
- Affordable rod, mirror, and boat offer art still renders white.
- Affordable reinforced/star rod upgrades still use their existing warm/cool tint.
- Unavailable offer art still uses the same `Color(1, 1, 1, 0.52)` appearance.
- Offer costs, hint labels, unlock checks, button behavior, and collection flows are unchanged.

Behavior intentionally removed:
- The unavailable fishing offer art tint literal is no longer duplicated across individual offer builders.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts fishing offer builders use `_fishing_offer_art_modulate()` and the unavailable tint has one named source.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` exited successfully, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. This run also emitted the intermittent existing `_update_skill_detail_shadow()` / `_set_canvas_item_modulate_if_changed()` dummy-renderer backtrace, so that remains a separate stability risk rather than clean validation evidence for the shadow path.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The intermittent skill-detail shelf shadow `Parameter "t" is null` backtrace still appears under the full project check and should be isolated in its own phase.
- Fishing area stat fades and method attempt-bar alpha writes are still animation/state blends and need targeted review before converting any of them to guarded setters.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.
- The full project check still emits unrelated Godot shutdown/resource warnings.

## Completed Phase 82: Skill Detail Shadow Draw Alpha

Risk reduced: the full project check intermittently emitted a `Parameter "t" is null` GDScript backtrace through `_update_skill_detail_shadow()` and `_set_canvas_item_modulate_if_changed()`. The shelf shadow is a custom draw-only `Control`, so using high-frequency `CanvasItem.modulate` writes for its fade mixed renderer state with custom draw state.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Skill detail shelf shadow alpha ownership
- Skill detail shadow update loop
- Static performance guard coverage for custom shadow alpha

Behavior intentionally preserved:
- The shelf shadow still uses the same visibility threshold.
- Visible shelf shadow fade behavior is preserved through the same `detail_shelf_shadow_alpha` value.
- Skill detail scrolling, jump arrows, swipe previews, header gauge updates, and shadow placement are unchanged.

Behavior intentionally removed:
- `_update_skill_detail_shadow()` no longer applies shelf shadow alpha through `_set_canvas_item_modulate_if_changed()`.
- `SkillDetailPageShelfShadow` now owns alpha as custom draw state through `set_shadow_alpha()`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts `SkillDetailPageShelfShadow` owns alpha through `set_shadow_alpha()` and `_update_skill_detail_shadow()` avoids high-frequency CanvasItem modulate writes.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` exited successfully, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The prior `_update_skill_detail_shadow()` GDScript backtrace did not reappear; the run still emitted a bare shutdown `Parameter "t" is null` renderer warning without a script backtrace.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including a bare `Parameter "t" is null` renderer warning without a GDScript backtrace.
- Fishing area stat fades and method attempt-bar alpha writes are still animation/state blends and need targeted review before converting any of them to guarded setters.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.

## Completed Phase 83: Tutorial Shadow Alpha Probe Ownership

Risk reduced: after moving the skill-detail shelf shadow fade from `CanvasItem.modulate` into `SkillDetailPageShelfShadow.shadow_alpha`, the tutorial-start validation still reported shelf shadow alpha from `modulate.a`. The test passed because it also checked `visible`, but its output claimed hidden shadows had alpha `1.0000`, which made validation evidence misleading for future shadow/debug work.

Files changed:
- `scripts/test-tutorial-start-scroll.ps1`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Tutorial-start scroll validation ownership for shelf shadow alpha
- Static regression coverage for shadow validation probes

Behavior intentionally preserved:
- Tutorial starter skill page assertions are unchanged: it still requires top scroll, hidden shelf shadow, no misplaced activity-start tip, and a bounded first-module gap.
- Game runtime behavior is unchanged.
- The test still falls back to `CanvasItem.modulate.a` for non-custom shadow controls.

Behavior intentionally removed:
- Tutorial-start validation no longer reports the shelf shadow's alpha from `CanvasItem.modulate.a` when the custom `shadow_alpha` property is available.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts tutorial-start validation reads the custom shelf shadow alpha state.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The tutorial-start output now reports `shadow_alpha=0.0000` for the hidden shelf shadow.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks, though the bare `Parameter "t" is null` renderer warning did not appear on this run.
- Fishing area stat fades and method attempt-bar alpha writes are still animation/state blends and need targeted review before converting any of them to guarded setters.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.

## Completed Phase 84: Guarded Alpha and Lazy Cache Parking

Risk reduced: fishing stat/attempt UI had final-state alpha writes that bypassed the shared guarded UI-write pattern, while full validation also exposed a lazy-card unmount warning from mutating a cached card root after detaching it from its stack host. These were both small ownership issues around final visual state, not animation timing.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Shared CanvasItem alpha-write ownership
- Fishing area instant stat visibility alpha
- Fishing method attempt-bar resting alpha
- Detail lazy-card cache parking boundary
- Static regression coverage for alpha guards and lazy cache parking

Behavior intentionally preserved:
- Fishing area stat fade tweens still own animated `modulate:a` transitions.
- Fishing area stat boxes still appear/disappear with the same target alpha.
- Fishing method attempt bars still use alpha `1.0` while running/revealing and `0.42` while idle.
- Lazy action/passive cards are still cached, hidden, parked, and remounted as before.

Behavior intentionally removed:
- Fishing instant stat visibility and attempt-bar resting alpha no longer assign `modulate.a` directly.
- Instance-id alpha callbacks now reuse the shared guarded alpha setter.
- Lazy unmount no longer removes `cached_root` directly before resetting its tint; `_park_detail_lazy_cached_root()` owns reset, detach, and hide.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts shared alpha writes are guarded, fishing alpha final states use the helper, fishing stat fade tweens remain tween-owned, and lazy cache parking owns cached-root reset/hide.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate. The lazy-unmount GDScript backtrace from the prior full run did not reappear.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- Other direct alpha writes remain in tutorial, swipe, modal, toast, and ceremony animation paths; those should be inspected one ownership boundary at a time before conversion.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.

## Completed Phase 85: Chat Strip Visibility Guards

Risk reduced: chat strip committed visibility and unread-dot sync used direct visibility assignments in a repeated update path. The logic already had one owner for when the strip/dot should show, but the final writes bypassed the shared guarded visibility setter and its queued-for-deletion protection.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat strip committed visibility ownership
- Chat unread-dot visibility sync
- Static regression coverage for chat visibility guards

Behavior intentionally preserved:
- Chat strip visibility rules, hide grace timing, force-hide behavior, stream connect/disconnect triggers, and line text sync are unchanged.
- The unread dot still appears only when the chat strip is visible and unread messages exist.
- Construction-time default hidden states are unchanged.

Behavior intentionally removed:
- Chat strip committed visibility no longer assigns `chat_strip.visible` directly.
- Chat unread-dot sync no longer assigns `chat_unread_dot.visible` directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts chat strip show/hide and unread-dot sync use `_set_canvas_item_visible_if_changed()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- Other direct visibility/alpha writes remain in chat overlay, tutorial, swipe, modal, toast, and ceremony paths; those should be inspected one ownership boundary at a time before conversion.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.

## Completed Phase 86: Chat Overlay Visibility Guards

Risk reduced: chat overlay open/close and mobile keyboard preview/fill updates used direct final-state visibility writes. These paths are repeated UI sync points, not tween-owned animation paths, so they belonged behind the shared guarded visibility setter like the chat strip.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Chat overlay visibility ownership
- Chat keyboard preview visibility ownership
- Chat keyboard fill visibility ownership
- Static regression coverage for chat overlay/keyboard visibility guards

Behavior intentionally preserved:
- Chat overlay open/close behavior, mouse filtering, stream connection, poll timer, read cursor updates, row sync, keyboard lift offsets, and preview text behavior are unchanged.
- Keyboard preview still shows only on supported mobile keyboard platforms while the overlay is visible and keyboard visibility is detected.
- Keyboard fill still follows the same `chat_keyboard_lift_pixels > 1.0` threshold.

Behavior intentionally removed:
- Chat overlay open/close no longer assigns `chat_overlay.visible` directly.
- Chat keyboard preview/fill sync no longer assigns their `visible` states directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts chat overlay, keyboard preview, and keyboard fill visibility writes use `_set_canvas_item_visible_if_changed()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- Other direct visibility/alpha writes remain in tutorial, swipe, modal, toast, ceremony, and non-chat overlay paths; those should be inspected one ownership boundary at a time before conversion.
- Wider swipe-cover, tutorial-overlay, and modal-overlay paths still mix animation writes with idempotent visibility resets.

## Validation Watchpoint: Skills Page Performance

Current status: `.\scripts\check-project.ps1` has alternated between passing and failing `.\scripts\test-skills-page-performance.ps1`. The latest full run passed, including `swipe/build` and `rapid_swipe/build`, so this remains a performance watchpoint rather than a data/save blocker.

Evidence gathered:
- Slow samples cluster while build action cards are lazily mounted after swipe finalization.
- `IDLE_ELITE_TRACE_PROCESS_SLOW=1` showed `_detail_lazy_mount_item()` / `_build_detail_interactive_action_card()` regularly taking several milliseconds for build cards.
- A narrow experiment that paused settle-warm mounting during swipe pressure was reverted because it shifted work into later measured frames and worsened the focused performance run.
- A second narrow experiment enabling the existing idle real-card prewarm and replacing recursive cached-card input enabling was also reverted. It improved some cached mounts but did not pass `swipe/build`, and it risked mixing scheduler/input behavior changes into the data/save cleanup.

Next safe direction:
- Profile card construction itself before changing scheduling again.
- Prefer reducing per-card construction cost or reusing already-built preview/card state over changing performance thresholds.
- Keep any performance cleanup separate from data/save ownership changes.

## Completed Phase 87: Modal and Tutorial Overlay Visibility Guards

Risk reduced: profile, settings, achievements, offline summary, and tutorial overlay paths still used direct runtime `visible` writes after chat overlay visibility had moved behind the shared guarded CanvasItem setter. These modal/tour paths are repeated open/close/sync points, so direct writes could reintroduce redundant UI churn and bypass queued-for-deletion protection.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Modal overlay open/close visibility ownership
- Tutorial overlay visibility sync
- Tutorial target indicator show/hide visibility ownership
- Static regression coverage for modal and tutorial visibility guards

Behavior intentionally preserved:
- Settings close still disarms reset confirmation and falls back to home when no overlay is open.
- Profile save/close still sanitizes names, saves the game, and refreshes leaderboard UI when needed.
- Starting tutorial still hides other overlays, resets to step 0, plays the same button SFX, and updates the tutorial overlay.
- Tutorial finish still hides the overlay/target indicator and plays the same button SFX.
- Achievements and offline summary open/close behavior, deferred rebuilds, background-input blocking, and pending achievement toast playback are unchanged.

Behavior intentionally removed:
- Runtime modal and tutorial overlay open/close/sync paths no longer assign `visible` directly.
- Tutorial target ring/label show and hide paths no longer assign `visible` directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts modal overlay, tutorial overlay, tutorial target indicator, achievements overlay, and offline summary visibility writes use `_set_canvas_item_visible_if_changed()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- Boot warmup, hub tutorial tip, swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but has historically been sensitive to lazy card construction cost.

## Completed Phase 88: Boot Warmup Final-State Guards

Risk reduced: boot warmup show/dismiss/hide completion and reveal prep used direct final-state visibility and alpha writes. Those paths are startup lifecycle sync points, while the actual fade transitions are tween-owned. Guarding the final-state writes keeps startup UI cleanup consistent with the shared CanvasItem write boundary and avoids touching queued-for-deletion overlay nodes during shutdown or rapid headless validation exits.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Boot warmup overlay show/hide visibility ownership
- Boot warmup overlay alpha reset ownership
- Boot warmup footer hide ownership
- Boot splash reveal-target alpha reset ownership
- Static regression coverage for guarded boot warmup final-state writes

Behavior intentionally preserved:
- Boot warmup still becomes active before startup work begins.
- Boot overlay mouse filtering still blocks input while visible and ignores input during dismissal.
- Boot progress text and progress bar behavior are unchanged.
- Boot overlay fade-out still uses the same `modulate:a` tween timing and easing.
- Boot splash background/splash/shade reveal fade still uses the same `modulate:a` tween timing and easing.

Behavior intentionally removed:
- Boot warmup runtime show/hide completion no longer assigns overlay `visible` or alpha directly.
- Boot warmup dismiss no longer assigns footer `visible` directly.
- Boot splash reveal prep no longer assigns reveal-target alpha directly.
- Boot warmup hide now refuses to start a fade tween on an overlay queued for deletion.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts boot warmup show, dismiss, hide completion, and reveal prep use guarded setters while fade tweens remain tween-owned.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The recurring dummy-renderer `Parameter "t" is null` warning appeared in this full run and still needs a separate asset/texture ownership investigation.
- Hub tutorial tip, swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 89: Hub Sheet Visual Texture Fallback Boundary

Risk reduced: hub module art refresh and hub build-smoke animation assigned `_hub_sheet_texture()` results directly to `TextureRect.texture`. `_hub_sheet_texture()` is intentionally nullable because it is a low-level atlas lookup, but visible TextureRect paths should not have to remember that. A missing or failed hub sheet could therefore bypass the shared visual fallback boundary and hand a null texture to the renderer.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub sheet visual texture ownership
- Hub module art refresh texture assignment
- Hub build-smoke animation texture assignment
- Static regression coverage for non-null hub sheet visual texture usage

Behavior intentionally preserved:
- Hub module art still uses the same module sheet, sprite index, 512x512 cell size, sizing, positioning, and depth z-index when the source sheet loads.
- Hub build smoke still advances through the same smoke sheet frames using the same timing and animation path when the source sheet loads.
- `_hub_sheet_texture()` remains nullable for low-level atlas lookup callers.

Behavior intentionally removed:
- Visible hub sheet TextureRect paths no longer assign nullable `_hub_sheet_texture()` results directly.
- `_hub_sheet_image()` now uses the same `_hub_sheet_or_visual_fallback()` helper as the direct refresh/animation paths.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts hub sheet visual fallback ownership for `_hub_sheet_image()`, `_refresh_hub_module_art()`, and `_process_hub_modules()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer null texture warning still appears, so this phase reduced one nullable TextureRect boundary but did not close the root warning. The latest full run included a GDScript backtrace through `_build_detail_interactive_action_card()`, `_detail_lazy_mount_item()`, and `_detail_lazy_settle_warm_mount()`, making action-card construction the next texture ownership investigation target.
- Hub tutorial tip, swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 90: Action Card Medal Texture Fallback

Risk reduced: action-card medal `TextureRect`s were created without a texture, then later hidden or populated by static card refresh. The latest full check's dummy-renderer warning included a backtrace through `_build_detail_interactive_action_card()` during lazy mounting, so textureless action-card children were a plausible renderer edge. The medal now has one explicit texture source of truth: real medal art for mastery levels above zero, and the shared transparent visual fallback for hidden zero-level medals.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Action-card medal texture ownership
- Zero-level hidden medal fallback behavior
- Medal placement and ceremony texture assignment
- Static regression coverage for non-null action-card medal textures

Behavior intentionally preserved:
- Medals still remain hidden when mastery level is zero.
- Existing medal art, placement, scale, rotation, pivot, and animation behavior are unchanged for mastery levels above zero.
- Medal replacement ceremonies still decide replacement from the existing explicit `replacing` boolean, not texture object identity.
- Convergence cards still hide medal UI.

Behavior intentionally removed:
- Action-card medal TextureRects no longer enter the scene tree without a texture.
- Zero-level hidden medals no longer restore `null` as their texture during placement updates.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts action-card medals enter the scene tree with a fallback texture and placement/ceremony paths use `_action_card_medal_texture_for_level()`.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning did not appear on this full run, but prior runs were intermittent; keep watching future full checks before calling the texture warning fully closed.
- Hub tutorial tip, swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 91: Hub Tutorial Tip Final-State Guards

Risk reduced: hub tutorial tip show/dismiss/hide lifecycle code mixed direct visibility and alpha final-state writes with tween-owned fade-in/fade-out animation. The tip is a small modal-like overlay that can be created, dismissed, and page-cleared around navigation, so its final-state writes should follow the shared guarded CanvasItem boundary and skip queued-for-deletion roots.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Hub tutorial tip show visibility ownership
- Hub tutorial tip alpha reset ownership
- Hub tutorial tip hide completion visibility ownership
- Hub tutorial tip queued-for-deletion guards
- Static regression coverage for guarded hub tutorial tip final-state writes

Behavior intentionally preserved:
- First-time hub tutorial tip display still marks `hub_tutorial_tip_seen` and saves.
- Manual and automatic tip display still use the same root UI, fade-in duration, and easing.
- Dismissal still reacts to hub presses, touches, and drags.
- Fade-in and fade-out still use the same tweened `modulate:a` animation.
- Hidden tips are still queued for free at the end of the fade-out.

Behavior intentionally removed:
- Hub tutorial tip show no longer directly assigns `visible` or alpha.
- Hub tutorial tip hide completion no longer directly assigns `visible`.
- Show, dismiss, and visibility checks now ignore roots queued for deletion.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts hub tutorial tip show/hide final-state writes use guarded helpers while fade tweens remain tween-owned.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning reappeared on this full run, again with a backtrace through `_build_detail_interactive_action_card()` and lazy mounting, so action-card texture ownership still needs more investigation.
- Swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 92: Rounded Action Card Texture Boundary

Risk reduced: action-card backgrounds now pass non-null textures through `_action_card_background_texture()`, but the shader-backed `RoundedTextureRect` control still accepted and stored nullable texture state internally. That left the rounded card control with a separate fallback branch during shader sync, so lazy-mounted cards could still depend on render-time null handling instead of one clear texture boundary.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Rounded action-card background texture ownership
- Rounded background shader parameter sync
- Rounded background mask-parameter caching
- Static regression coverage for non-null rounded background shader textures

Behavior intentionally preserved:
- Action-card background art, crop settings, rounded mask settings, convergence contain-mode behavior, and skill fallback colors are unchanged.
- Missing or failed background art still resolves to the existing transparent fallback texture and the rounded card's existing fallback color.
- Shader parameter caching still skips repeated writes when the effective texture and mask parameters have not changed.

Behavior intentionally removed:
- `RoundedTextureRect` no longer stores caller-assigned `null` textures after a texture assignment.
- Rounded background shader sync no longer owns an inline nullable texture expression when setting `bg_texture`.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts rounded card backgrounds normalize null texture assignments, resolve an effective texture once before shader sync, pass that resolved texture to the shader, and cache the effective texture after syncing.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.
- `git diff --check` reported only LF-to-CRLF warnings for touched scripts.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning still appeared on this full run, but the backtrace moved to `_update_action_card_static_state()` at the refresh-time `art_panel.material = null` reset after lazy mounting. That should be the next isolated action-card cleanup phase.
- Swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 93: Action Card Material Reset Ownership

Risk reduced: action-card static refresh still cleared `art_panel.material` and `art.material` when the unlocked state changed. That was a leftover compatibility path from an unused locked-card material shim, and it overlapped with two real material owners: `ActionArtTextureRect` owns its rounded-mask shader material, and the thieving jail visual owns temporary grayscale materials through explicit original-material metadata. Clearing materials during ordinary static refresh could therefore remove the action-art mask or interfere with jail material restoration.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Action-card static refresh material ownership
- Action-art rounded-mask material preservation
- Thieving action jail grayscale material ownership
- Static regression coverage for removed locked-material compatibility code

Behavior intentionally preserved:
- Action-card unlocked/locked refresh still updates labels, stat chip styles, mission badges, lock overlays, shade visibility, button state, background tint, art-panel tint, borders, and locked-preview presence.
- Action art still uses its existing rounded-mask shader material.
- Thieving jail grayscale still applies and restores temporary materials through `thieving_jail_original_material` metadata.

Behavior intentionally removed:
- Action-card static refresh no longer clears `art_panel.material`.
- Action-card static refresh no longer clears `art.material`.
- The unused `locked_activity_material` variable and `_locked_activity_material()` shader factory were removed.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts action-card static refresh does not clear materials, the unused locked-material shim stays removed, and thieving jail grayscale remains the explicit owner of original-material restore.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.
- `git diff --check` reported only LF-to-CRLF warnings for touched scripts.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning did not appear on this full run after removing the refresh-time material clears, but prior runs were intermittent; keep watching future full checks before treating the texture warning as fully closed.
- Swipe-cover, ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 94: Skill Swipe Cover Final-State Guards

Risk reduced: the skill swipe handoff/rebuild cover protects page rebuilds, lazy-card mounting, and queued swipe finalization from exposing partial content. Its lifecycle still wrote visibility and opacity directly in several hold/cancel/finish paths while other high-frequency UI final-state writes had moved behind the shared live-node guards. That made the transition cover a fragile exception in one of the highest-regression UI flows.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Skill swipe handoff cover final-state visibility ownership
- Skill swipe cover opaque-hold ownership
- Skill swipe cover fade-cancel recovery
- Queued swipe finalize cover restoration
- Static regression coverage for guarded swipe-cover final-state writes

Behavior intentionally preserved:
- Animated skill swipes still use the same single cream transition cover.
- Page rebuilds and lazy-card mounting still keep the cover opaque until the target detail page is ready.
- Cover fade durations, easing, readiness checks, pending-finalize holds, queued-swipe handoff, and trace logging are unchanged.
- Construction-time cover defaults remain direct assignments on newly created nodes.

Behavior intentionally removed:
- Runtime swipe-cover cleanup no longer directly assigns `visible = false` before freeing.
- Runtime opaque-hold/recovery paths no longer directly assign `visible = true` or `modulate = Color.WHITE`.
- Tween-method alpha steps now use the shared alpha guard instead of assigning `cover.modulate.a` directly.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts swipe-cover hold, force-opaque, fade-cancel, ready-hold, fade-to-opaque, immediate cleanup, and queued finalize paths use the shared CanvasItem guards.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.
- `git diff --check` reported only LF-to-CRLF warnings for touched scripts.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning did not appear on this second consecutive full run, but keep watching future full checks before treating the texture warning as fully closed.
- Ceremony, toast, and preview reveal paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 95: Activity Preview Reveal Final-State Guards

Risk reduced: normal locked-activity preview reveal staging and fade completion mixed direct root/lock-overlay visibility and modulate writes with tween-owned reveal animation. These previews are created, hidden, restored, and revealed around unlock ceremonies and lazy-mounted detail cards, so final-state writes should share the same live-node guard boundary as the swipe cover and action-card refresh paths.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity preview enter staging final-state ownership
- Activity preview fade-in start and completion ownership
- Locked preview presence restore/hide ownership
- Locked preview overlay completion ownership
- Static regression coverage for guarded preview reveal writes

Behavior intentionally preserved:
- Activity preview fade duration, easing, height expansion, pop-card settle offset, onboarding level-up tip behavior, and lock-rig drop animation are unchanged.
- Hidden locked previews still collapse to zero height and restore their saved height/clip state.
- Locked preview overlays still remain visible and active when the preview is revealed but the action is still locked.
- Existing tween alpha updates still route through `_set_canvas_item_alpha_safe()`.

Behavior intentionally removed:
- Activity preview staging and fade-in no longer directly assign root visibility or fade-start modulate.
- Activity preview completion no longer directly assigns root or lock-rig final modulate.
- Locked preview overlay completion no longer directly assigns overlay/rig visibility or rig modulate.
- Locked preview presence sync now skips invalid or queued-for-deletion roots before reading/restoring layout state.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts preview staging, fade-in, fade completion, lock-overlay completion, and locked-preview presence sync use guarded CanvasItem writes and queued-root checks.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.
- `git diff --check` reported only LF-to-CRLF warnings for touched scripts.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning did not appear on this third consecutive full run, but keep watching future full checks before treating the texture warning as fully closed.
- Ceremony and toast paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Thieving heist preview fade-in has its own parallel preview reveal path and should be reviewed separately before assuming all preview reveal code follows this model.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 96: Thieving Heist Preview Reveal Guards

Risk reduced: thieving heist preview reveal has its own parallel staging/fade/completion path separate from normal activity preview reveal. It directly assigned root/pop visibility and modulate while also running a reveal tween, so the heist path remained a fragile exception to the guarded final-state ownership model.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Thieving heist preview staging final-state ownership
- Thieving heist preview fade completion ownership
- Thieving heist queued-root guards
- Static regression coverage for guarded heist preview reveal writes

Behavior intentionally preserved:
- Heist preview reveal target height, collapsed start height, root clipping, pop anchor restoration, pop offset tween, fade timing, easing, and delayed pop fade are unchanged.
- The pop alpha fade remains tween-owned through `tween_property(pop, "modulate:a", 1.0, 0.36)`.
- Heist preview cleanup still clears the same reveal metadata and releases extra unlock scroll space.

Behavior intentionally removed:
- Heist preview staging no longer directly assigns root visibility, root opacity, or pop fade-start opacity.
- Heist preview fade-in now skips root/pop controls queued for deletion before starting the tween.
- Heist preview completion no longer directly assigns final root/pop opacity.

Validation:
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts heist preview staging/fade/completion use queued-node guards and guarded CanvasItem final-state writes while the pop alpha tween remains tween-owned.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.
- `git diff --check` reported only LF-to-CRLF warnings for touched scripts.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- The dummy-renderer `Parameter "t" is null` warning reappeared on this full run without a GDScript backtrace, so the remaining texture warning should be treated as an unresolved renderer/shutdown cleanup risk rather than closed.
- Ceremony and toast paths still mix direct visibility and alpha writes with animation ownership; each needs a separate ownership review before conversion.
- Skills page performance remains a watchpoint because swipe/build passed on this run but still logged slow lazy-card construction samples.

## Completed Phase 97: Action Card Medal Ceremony Guards

Risk reduced: the action-card medal ceremony still mixed direct visibility and opacity writes with tween-owned animation state. That made the ceremony a fragile exception to the newer guarded CanvasItem ownership model, especially when action cards are refreshed, hidden, or reused while a medal animation is settling.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Action-card medal placement final-state ownership
- Action-card medal ceremony fade-start ownership
- Action-card medal ceremony completion ownership
- Static regression coverage for guarded medal ceremony writes

Behavior intentionally preserved:
- Medal texture selection, fallback texture behavior, destination placement, scale, rotation, anticipation motion, fade-in timing, replacement medal fall animation, and ceremony cleanup are unchanged.
- The medal fade-in remains tween-owned through `tween_property(medal, "modulate:a", 1.0, 0.12)`.

Behavior intentionally removed:
- Medal placement no longer directly assigns visibility or final modulate.
- Medal ceremony setup no longer directly assigns visibility or fade-start modulate.
- Medal ceremony completion now skips queued-for-deletion medals and no longer directly assigns final modulate.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts medal placement/setup/completion use guarded CanvasItem writes while the alpha fade remains tween-owned.
- `.\scripts\audit-activity-database.ps1` passed.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\scripts\test-save-normalization.ps1` passed with clean output.
- `.\scripts\check-project.ps1` passed after the Phase 98 shader-sync follow-up, including `leaderboard-cost-safety-ok`, the save-normalization gate, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings, including CanvasItem and texture/resource leaks.
- Other ceremony and toast paths still need separate ownership review before conversion.
- Skills page performance remains a watchpoint.

## Completed Phase 98: Rounded Background Shader Sampler Guard

Risk reduced: rounded action-card backgrounds re-sent the shader sampler texture whenever any mask parameter changed, even when the effective texture was unchanged. During stat-popup refreshes this created unnecessary renderer texture churn and reproduced the dummy-renderer `Parameter "t" is null` warning through `RoundedTextureRect._update_mask_params`.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- RoundedTextureRect shader parameter ownership
- Activity stat-popup background refresh texture sync
- Static regression coverage for sampler updates that are separate from non-texture mask parameter updates

Behavior intentionally preserved:
- Rounded background shader, fallback texture selection, crop parameters, feathering, art height, corner mask mode, aspect mode, and fallback color behavior are unchanged.
- The sampler still updates immediately when the effective texture actually changes.

Behavior intentionally removed:
- Rounded backgrounds no longer re-send `bg_texture` on every size, crop, feather, art-height, or fallback-color sync.
- Rounded background shader sync now skips safely if the fallback texture is unavailable during shutdown.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts rounded backgrounds resolve the effective texture once, skip null texture sync, and update the sampler only when the effective texture changes.
- `.\scripts\test-skills-page-performance.ps1` passed; the previous `RoundedTextureRect._update_mask_params` dummy-renderer `Parameter "t" is null` backtrace did not recur.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, save normalization, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- The full project check still emits shutdown/resource warnings and RID/resource leak messages.
- A separate dummy-renderer `Parameter "t" is null` warning now points near `_add_skill_detail_shadow_overlay_to` during the stamina-gauge validation path; this appears separate from rounded background sampler churn and remains open.
- Skills page performance passed, but swipe/build still logs slow sample frames and should remain a watchpoint.

## Completed Phase 99: Reward Float Tween Lifecycle Helper

Risk reduced: normal reward floats and action-opportunity reward floats duplicated the same holder fade/scale/rise/queue-free tween lifecycle. That duplication made the toast/float feedback bucket harder to patch safely and left each caller responsible for its own fade-start alpha write and cleanup callback.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Reward float tween ownership
- Opportunity reward float tween ownership
- Queued-node guards before reward float layout reads
- Static regression coverage for shared reward-float lifecycle

Behavior intentionally preserved:
- Reward float text, colors, shadow text, size, z-index, position clamping, rise distance, delay, scale timing, fade timing, and queue-free completion are unchanged.
- Opportunity feedback still appears at the opportunity rail feedback position and rises by the same amount.

Behavior intentionally removed:
- Opportunity reward floats no longer duplicate the holder fade/scale/rise tween setup.
- Reward floats no longer directly assign fade-start modulate in each caller; the shared helper owns the guarded fade-start write.
- Reward float entry points now skip parents, anchors, or rails queued for deletion before reading layout.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts reward floats and opportunity reward floats use `_start_reward_float_tween()`, queued-node guards are present, fade-start opacity is guarded, alpha tweens remain tween-owned, and queue-free cleanup stays centralized.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, save normalization, and the skills page performance gate.
- Verified no headless Godot process remained after the Godot validation command.

Remaining risks:
- Full project validation still emits shutdown/resource warnings and intermittent dummy-renderer `Parameter "t" is null` output without a stable backtrace.
- Achievement toast card transitions still have their own lifecycle and should be reviewed separately before treating the toast bucket as simplified.
- Skills page performance passed, but swipe/build still logs slow sample frames and should remain a watchpoint.

## Completed Phase 100: Achievement Toast Lifecycle Guards

Risk reduced: achievement toast presentation, card transition, dismissal, badge sync, and pruning each owned pieces of live-node checks, tween cleanup, and final alpha writes. That made the toast lifecycle fragile when a toast was tapped, auto-dismissed, transitioned to a queued card, or queued for deletion while callbacks were still pending.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Achievement toast live-node ownership
- Achievement toast tween cleanup ownership
- Achievement toast badge lookup/pruning guards
- Achievement toast transition final-state writes
- Static regression coverage for toast lifecycle guards

Behavior intentionally preserved:
- Achievement toast queueing, duplicate-id suppression, presentation position, card content, badge count, tap dismissal, automatic dismissal, next-card transition timing, exit timing, and queue drain scheduling are unchanged.
- Toast alpha fades remain tween-owned during presentation, card transition, and exit.

Behavior intentionally removed:
- Toast callers no longer duplicate direct active-tween cleanup logic.
- Toast lifecycle callbacks now share `_achievement_toast_live()` and skip controls queued for deletion.
- Toast presentation and card-transition final opacity writes now use guarded CanvasItem setters.
- Toast badge lookup now drops queued-for-deletion badge controls instead of retaining stale metadata.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts the shared toast live-node guard, shared tween cleanup helper, guarded fade-start/final alpha writes, queued badge pruning, and toast pruning ownership.
- `.\scripts\check-project.ps1` passed, including `leaderboard-cost-safety-ok`, save normalization, and the skills page performance gate.
- Verified no headless Godot process remained after the Godot validation command.

Remaining risks:
- Full project validation still emits shutdown/RID/resource warnings and intermittent dummy-renderer `Parameter "t" is null` output without a stable backtrace.
- Achievement toast visual/card construction is still large and could be split later, but lifecycle ownership is now centralized.
- Skills page performance passed, but swipe/build still logs slow sample frames and should remain a watchpoint.

## Completed Phase 101: Activity Crit Overlay Cleanup Helper

Risk reduced: activity crit feedback owned several local cleanup branches for stale highlight, art-burst, and crit-text overlay nodes. Each branch directly hid the node, optionally killed a text tween, and queued the node for deletion, which made repeated crit feedback and callback cleanup harder to keep consistent.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Activity crit overlay cleanup ownership
- Activity crit text tween cleanup ownership
- Activity crit completion cleanup
- Static regression coverage for shared crit overlay cleanup

Behavior intentionally preserved:
- Activity crit and mega-crit card shake, glow, text burst, art burst, timing, scale, fade, drift, sound triggering, and metadata restoration are unchanged.
- Crit text fade remains tween-owned.

Behavior intentionally removed:
- Stale crit highlight, art burst, and text nodes no longer duplicate direct `visible = false` plus `queue_free()` cleanup.
- Crit text cleanup now uses the shared meta-tween killer before queueing the holder for deletion.
- Crit overlay cleanup now skips nodes already queued for deletion and routes final visibility through the guarded CanvasItem setter.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts activity crit overlay cleanup skips queued nodes, owns optional meta-tween cleanup, guards final visibility writes, and is used by stale-node and callback cleanup paths.
- Initial `.\scripts\check-project.ps1` run reached the skills-page performance gate and failed on the known intermittent swipe/build p99/max-frame budget miss.
- Focused `.\scripts\test-skills-page-performance.ps1` passed on rerun.
- Second `.\scripts\check-project.ps1` run passed, including `leaderboard-cost-safety-ok`, save normalization, and the skills page performance gate.
- Verified no headless Godot process remained after each Godot validation command.

Remaining risks:
- Full project validation still emits shutdown/RID/resource warnings and resource leak messages.
- Skills page swipe/build performance remains flaky enough to occasionally fail the full gate even when a focused rerun passes.
- Other feedback paths still have local cleanup/final-state ownership and should be reviewed one bounded path at a time.

## Completed Phase 102: Music Cycle Stream Reuse And Audit Reliability

Risk reduced: each music cycle rebuilt music players and loaded loop resources even when the selected song set already matched the prepared player pool. The leaderboard cost-safety audit also used an overly broad regex across `main.gd`, which could hang validation before later project gates ran.

Files changed:
- `scripts/main.gd`
- `scripts/test-performance-regressions.ps1`
- `scripts/check-project.ps1`
- `scripts/check-leaderboard-cost-safety.ps1`
- `docs/efficiency-audit-tracker.md`
- `docs/audio-structure-guide.md`
- `docs/agent-onboarding-checklist.md`
- `docs/codebase-stabilization-audit.md`

Systems simplified:
- Music loop stream ownership
- Music cycle player reuse contract
- Static regression coverage for music stream caching
- Leaderboard audit function-body extraction
- Audio documentation for runtime-only music state
- Agent onboarding baseline for non-strict skills-page performance warnings
- Non-strict skills-page performance retry output in the full project harness

Behavior intentionally preserved:
- Music still starts only through the existing probabilistic music-flow rules.
- Song set weights, layer volume boosts, fade timings, quiet breaks, bus routing, and audio-unlock gating are unchanged.
- Music players still rebuild when the selected song set name, layer count, or track paths differ.
- Music players still rebuild if a prepared player node is stale or its stream no longer matches the selected track path.
- Leaderboard runtime behavior is unchanged; only the static cost-safety audit changed.

Behavior intentionally removed:
- Same-song-set music cycles no longer reload the same loop streams or recreate the prepared music player pool.
- Music loop loading no longer lives inline in `_build_music_players()`.
- The leaderboard cost-safety audit no longer runs the submit-safety assertion as a broad whole-file regex.
- The agent onboarding checklist no longer describes the current non-strict skills-page performance warning as a hard validation failure.
- Non-strict skills-page performance retries no longer dump full failure output for attempts that will be retried.

Validation:
- `.\scripts\test-performance-regressions.ps1` passed. It now asserts music streams use `music_stream_cache`, music player construction loads through `_load_music_stream()`, same-set reuse checks song-set name/layer count/track paths/player validity/stream identity, changed sets still rebuild, the onboarding/codebase maps document the current non-strict skills-page performance warning, and the project harness summarizes retried skills-page failures before printing only the final failed sample.
- `.\scripts\check-leaderboard-cost-safety.ps1` passed.
- `.\run-godot-safe.ps1 --headless --path . --quit-after 1` passed.
- `.\scripts\check-project.ps1` exited successfully, including `leaderboard-cost-safety-ok`, save normalization, and the performance regression gate.
- Verified no headless Godot process remained after Godot validation commands.

Remaining risks:
- Full project validation still emits shutdown/RID/resource warnings and resource leak messages.
- The non-strict skills-page performance gate can still miss all retries and print the final failed sample before continuing with `skills-page-performance-release-warning`.
- This pass did not include live audio listening, so the efficiency tracker still marks music reuse as awaiting live audio confirmation.
