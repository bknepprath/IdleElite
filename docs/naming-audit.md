# Naming Audit

This audit treats naming as architecture work. The goal is to improve names that help future debugging, common workflows, and safe changes while avoiding churn in serialized, data-driven, scene-bound, or externally referenced names.

## Naming Clusters

### Main runtime controller

`scripts/main.gd` is still the primary coordination point for game state, navigation, UI construction, lazy rendering, and save/load boundaries. Its names mostly use domain prefixes, which is helpful, but the file also contains several dense clusters where similar terms overlap.

- `skill_swipe_*`: swipe navigation, page preview state, transition covers, deferred lazy mounting, paper fade overlays, and commit/finalize state.
- `detail_lazy_*`: lazy render plans, cached roots, placeholders, scroll hosts, mounted pages, and pinned/visible entries.
- `activity_unlock_*`, `pending_activity_unlock_*`, `detail_unlock_*`: unlock ceremony state, readiness state, preview matching, and detail-screen unlock routing.
- `action_opportunity_*`: timed/conditional action opportunity state, cycles, boosts, miss accounting, persistent windows, and reward metadata.
- `fishing_*`: fishing locations, areas, tools, offers, wallet UI, catches, rewards, and the activity database bridge.
- `manual_activity_unlock*`: explicitly unlocked activities and manually satisfied requirements. These names sit near save compatibility boundaries.
- `boot_detail_*`, `screen_render_*`, `pending_screen_render_*`: startup/detail navigation and deferred screen rendering.
- `page_stash*`, `park_*`, `handoff_*`, `cached_*`: retained page roots and temporary holders used during navigation and lazy rendering.

### Extracted UI controls

The extracted `scripts/ui` controls have a clearer class/file naming style than the root controller. The strongest pattern is `class_name PascalCase` plus a matching snake_case file name:

- `ActivityProgressRail` in `activity_progress_rail.gd`
- `ActivityProgressOpportunityOverlay` in `activity_progress_opportunity_overlay.gd`
- `FishingToolWalletOverlay` in `fishing_tool_wallet_overlay.gd`
- `MobileScrollContainer` in `mobile_scroll_container.gd`
- `RoundedTextureRect` in `rounded_texture_rect.gd`
- `ActionArtTextureRect` in `action_art_texture_rect.gd`

Some extracted controls still contain generic local names such as `source`, `value`, `icons`, `shadows`, `radius`, and `fill_color`. These are acceptable when tightly scoped, but the more reused controls should prefer names that reveal the domain role of the value.

### Data and content naming

The fishing rework has a useful source-of-truth convention:

- `docs/activity-database.json` owns fishing areas and per-action area mapping.
- Sync/audit scripts bridge that data into runtime modules.
- Fishing runtime names should distinguish `area`, `location`, `tool`, `offer`, `catch`, and `reward` instead of using generic UI or data words.

This cluster is high value for future maintainability, but many identifiers are data IDs or save-facing fields and need compatibility handling before renaming.

## Risky Identifiers To Skip Without Compatibility Handling

Do not rename these categories through simple refactors:

- Serialized save keys and restored fields, including manual unlock state, selected fishing locations, seen/tip flags, hub/chat/thieving/fishing state, leaderboard data, and unlock flags.
- Public data IDs, skill IDs, action IDs, area IDs, location IDs, tool IDs, offer IDs, and any IDs stored in `docs/activity-database.json` or consumed by synced runtime data.
- Asset paths, `res://` references, `.import` metadata, generated `.gd.uid` files, and content file names that may be referenced externally.
- Node names, scene-bound names, groups, meta keys, signal names, input/action names, and localization or user-facing strings.
- Test selectors or regression fixture strings unless the test itself proves the string is internal.
- The current uncommitted swipe paper-fade work in `scripts/main.gd`. That cluster should be resolved or discarded before rename commits touch swipe/fade symbols.

## Patterns Worth Preserving

- Preserve `class_name PascalCase` for extracted controls and snake_case file names that match the class.
- Preserve Godot-style private helper prefixes such as `_build_*`, `_render_*`, `_sync_*`, `_restore_*_from_save`, `_apply_*`, `_clear_*`, `_ensure_*`, `_queue_*`, and `_finish_*`.
- Preserve domain prefixes such as `fishing_`, `activity_unlock_`, `detail_lazy_`, `skill_swipe_`, and `action_opportunity_` where they make reference search and ownership clear.
- Preserve `_for_save` and `_from_save` suffixes at compatibility boundaries.
- Prefer names that identify the domain object before the implementation detail: `progress_rail`, `tool_button_rects`, `readiness_action_ids`, `lazy_entry`, `transition_cover`.
- Keep rename commits grouped by concept, with reference inspection before each commit and regression coverage when a rename touches behavior-sensitive paths.

## First 5 Safe High-Value Rename Targets

1. Rename `source` inside `ActivityProgressOpportunityOverlay` to `progress_rail`.
   - Why: `source` hides that the overlay samples an activity progress rail.
   - Scope: `scripts/ui/activity_progress_opportunity_overlay.gd` and call sites only.
   - Safety: extracted control internals; no save/data compatibility expected.

2. Rename wallet overlay internals in `FishingToolWalletOverlay`.
   - Candidate names: `button_rects` to `tool_button_rects`, `tool_ids` to `wallet_tool_ids`, `tool_icons` to `wallet_tool_icons`, and `unlocked_states` to `tool_unlocked_states`.
   - Why: the control manages a specific fishing wallet, not arbitrary button/icon state.
   - Scope: `scripts/ui/fishing_tool_wallet_overlay.gd` and immediate call sites.
   - Safety: extracted UI control internals; avoid changing user-facing tool IDs.

3. Rename `_pending_activity_ready_ids` to `_pending_activity_readiness_action_ids`.
   - Why: the current name reads like generic pending activity IDs, but the values represent action IDs currently eligible for unlock readiness treatment.
   - Scope: internal `scripts/main.gd` helper and tests/assertions that reference it.
   - Safety: private helper; inspect with `rg` before editing.

4. Rename pending unlock matcher helpers to clarify readiness versus preview.
   - Candidate names: `_pending_activity_unlock_matches` to `_action_has_pending_unlock_readiness` and `_pending_activity_unlock_preview_matches` to `_action_matches_pending_unlock_preview`.
   - Why: "pending unlock matches" does not say whether it checks actual readiness state or preview display state.
   - Scope: internal `scripts/main.gd` helpers and direct references.
   - Safety: private helpers; behavior-sensitive, so update focused regression assertions if present.

5. Rename the first small slice of `detail_lazy_*plan_item*` helpers to `detail_lazy_*entry*`.
   - Candidate names: `_detail_lazy_plan_item_pinned` to `_detail_lazy_entry_is_pinned`, `_detail_lazy_plan_item_for_track_id` to `_detail_lazy_entry_for_track_id`, and `_detail_lazy_plan_item_matches_track_id` to `_detail_lazy_entry_matches_track_id`.
   - Why: "entry" better describes one lazy render-plan record, while "plan item" is verbose and inconsistently used with local variables.
   - Scope: helper functions and local call sites in `scripts/main.gd`.
   - Safety: private helpers; larger reference surface, so keep as its own commit.

## Deferred But Important

The swipe/navigation cluster needs naming work, especially around `cover`, `handoff`, `preview`, `page`, `frame`, `commit`, and `finalize`. It should not be the first rename target because the worktree currently contains uncommitted swipe fade changes. Once that state is clean, the safest approach is to rename one concept at a time and validate the swipe page fade regression after each commit.
