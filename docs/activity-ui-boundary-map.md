# Activity UI Boundary Map

Use this map before editing activity detail pages, action cards, mastery medals, unlocks, and offline summary code in `scripts/main.gd`. These regions are tightly coupled to save data, lazy rendering, mobile gestures, and visual performance, so behavior-neutral readability work should name the boundary before moving code.

## Stable Entry Points

| Boundary | Main entry points | Notes |
| --- | --- | --- |
| Skill detail shell | `_render_skill_detail`, `_detail_stack_entry`, `_build_detail_lazy_plan`, `_build_detail_jump_arrows`, `_add_activity_back_arrow` | Owns the scroll stack, lazy card plan, jump arrows, and back navigation. Protected by skill-detail geometry/performance checks. |
| Action cards | `_build_detail_interactive_action_card`, `_activity_card_root_height`, `_activity_card_preview_root_height`, `_activity_card_depth_layer`, `_activity_card_shade_layer` | Owns the main repeated module card. Avoid visual tweaks during naming-only changes. |
| Passive and special modules | `_build_passive_module_card`, `_build_thieving_heist_card`, `_build_fishing_area_module`, `_build_fishing_offer_module` | Owns non-standard detail modules that still share card, collapse, and lazy-render expectations. |
| Mastery medals | `_mastery_level`, `_mastery_progress_pct`, `_mastery_medal_texture`, `_mastery_medal_visual_texture`, `_mastery_for_save` | Mastery is both UI and save data. Preserve canonical action keys and fallback textures. |
| Unlocks and lockpads | `_unlock_padlock_pulse_texture`, `_unlock_padlock_tint_mask_texture`, `_action_has_pending_unlock_readiness`, `_apply_pending_activity_unlock_readiness` | Unlock UI touches manual unlock state, pending ceremony state, and auto-unlock behavior. |
| Offline summary | `_maybe_show_offline_summary`, `_offline_summary_activity_card`, `_offline_summary_stat_card`, `_offline_summary_mastery_row`, `_offline_summary_unlock_card` | Owns the away-progress overlay and must preserve save/load and visibility guards. |
| Offline rewards | `_offline_active_cycle_seconds`, `_offline_xp_reward`, `_offline_mastery_reward`, `_offline_unlocked_actions` | Gameplay math lives near UI summary rendering. Do not mix math changes into visual refactors. |

## Working Rules

- Keep activity-card construction, lazy render plans, and save payload changes in separate commits unless one change cannot work without the other.
- When renaming locals, prefer domain names such as `lazy_entry`, `render_record`, `activity_def`, `action_id`, `module_key`, and `unlock_requirement`.
- Run `.\scripts\check-activity-ui-boundary-contracts.ps1`, `.\scripts\test-activity-card-geometry.ps1`, `.\scripts\test-save-normalization.ps1`, and the relevant skill-detail checks after edits in these areas.
- Do not rename save keys, action IDs, skill IDs, module UI keys, or generated activity data fields without compatibility handling.
