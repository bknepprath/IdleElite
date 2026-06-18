# UI Runtime Boundary Map

Use this map before editing high-traffic shell UI in `scripts/main.gd`. The goal is to keep navigation, home, shop, chat, leaderboard, and profile changes scoped to their owning regions instead of drifting into unrelated helpers.

## Stable Entry Points

| Boundary | Main entry points | Notes |
| --- | --- | --- |
| Home and navigation shell | `_build_home_page`, `_build_nav_bar`, `_nav_button`, `_apply_nav_style`, `_show_skills`, `_show_shop` | Owns the first screen, bottom navigation, and top-level screen switching. Preserve `current_screen` values and bottom-safe-area behavior. |
| Shop and ads | `_show_shop`, `_shop_unlocked`, `_shop_ad_offer_button`, `_shop_ad_pressed`, rewarded-ad callbacks | Keep ad behavior and release/test ad IDs out of readability-only refactors. Device validation is needed for real ad changes. |
| Chat transport | `_chat_stream_connect`, `_chat_send`, `_chat_apply_stream_payload`, `_chat_sort_and_trim_rows` | Owns Firebase chat I/O, rate limits, and row normalization. Preserve cost-safety and auth guard behavior. |
| Chat presentation | `_build_chat_strip`, `_build_chat_overlay`, `_chat_strip_visible_on_current_screen`, `_chat_row`, `_chat_composer` | Owns the collapsed strip, expanded overlay, unread display, and mobile keyboard behavior. |
| Leaderboard networking and data | `_leaderboard_fetch_category`, `_leaderboard_submit_scores`, `_leaderboard_categories`, `_leaderboard_score_for_category` | Protected by leaderboard cost-safety and Firebase config/runtime guard tests. Do not bypass cache or submit cooldowns. |
| Leaderboard page | `_render_leaderboard_page`, `_leaderboard_page_frame`, `_leaderboard_player_card`, `_leaderboard_row` | Owns visible leaderboard layout. Keep category IDs, Firebase keys, and profile fields compatible. |
| Profile/avatar UI | `_build_profile_overlay`, `_profile_avatar_picker_button`, `_profile_avatar_texture`, `_profile_avatar_frame` | Owns display-name entry and avatar choice. Preserve saved avatar/profile keys. |

## Working Rules

- Refactor one boundary at a time and keep behavior/visual changes out of naming or movement commits.
- If a function crosses boundaries, leave a note in this map before moving it so the next agent understands the coupling.
- Run `.\scripts\check-ui-boundary-contracts.ps1` after edits in these regions, then run the narrower Firebase, chat, or visual checks that match the boundary.
- Avoid committing pre-existing feature work from the dirty tree as a boundary refactor. Stage only the files and hunks owned by the current package.
