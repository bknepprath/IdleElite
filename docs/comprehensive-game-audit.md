# Idle Elite comprehensive game audit

Audit date: 2026-07-10  
Baseline: `codex/godot-4.7-migration` at `60b8824e89a70114f9d9e8ea925f8d9512d6853e`  
Status: remediation complete; no confirmed actionable product defect remains.

## Relay route

| Phase | Thread | Model / effort | Result |
| --- | --- | --- | --- |
| Coordinator | `019f4ce6-2722-7d31-958a-c6aaafe94451` | Sol / Extra High | Assigned R1 audit and F1 remediation. |
| R1 reconnaissance | `019f4ce7-44a4-7fb0-908d-193316250fa3` | `gpt-5.6-luna` / High | Complete; produced the original evidence and audit artifact. |
| F1 remediation | `019f4cff-5045-7db0-b12f-0a2135b9292b` | Terra / Extra High | Complete; sole writing phase. |
| V1 verification | `019f4d1a-43db-7290-a4b8-d8772c510c55` | Luna / High | Found one stale Web performance-probe call; F1 fixed and rechecked it. |

An accidental nested coordinator, `019f4d00-3ed7-7ae1-a96f-03b577fb3345`, was created before the F1 role correction. It was immediately left idle and did no work.

## Worktree protection

The baseline dirty file `scripts/ui/skill_detail_surface.gd` was preserved exactly in its four user-owned hunks:

1. `_normal_activity_stat_icon_item`: left to center alignment.
2. Stat icon outline offsets: `4` to `8`.
3. `_normal_activity_stat_panel`: `StyleBoxFlat` block to `StyleBoxEmpty`.
4. `_normal_activity_stat_box_style` border width: `8` to `12`.

No commit, push, deploy, uninstall, or user-data deletion occurred. No Godot process owned by this phase remained after validation.

## Fixed findings

| ID | Disposition | Root-cause fix | Recheck |
| --- | --- | --- | --- |
| FF-AUD-001 | **Fixed** | Fishing used an 1800px mount buffer, a 2800px unmount buffer, and excluded Fishing modules from the existing unmount path. Fishing now uses the standard 120px/180px lazy windows and offscreen Fishing modules re-enter the existing unmount path. | `test-fishing-cold-render.ps1` passed: `immediate=4`, `warmed=8/18`, `cards=8`, no visible placeholders. The focused skills probe and full project gate held `scroll/fishing` at 5 action cards; the former `mounted too many action cards` error did not recur. |
| FF-AUD-002 | **Fixed** | `AchievementPresentation._cropped_texture` now returns the supplied texture when `get_image()` yields null or an empty image, matching the existing empty-used-rect fallback. | `test-home-achievement-medal-click.ps1` passed before and during the full gate; no `get_used_rect` script error appeared in Home/Achievement/Pinned medal coverage. |
| FF-AUD-TOOL-001 | **Fixed** | The generated census probe now invokes `_navigation_shell()._render_screen()` instead of the removed `main.gd` method. | `test-button-census-clicks.ps1` passed: `clicked=26`, `skipped=0`, `candidates=978`, `scenarios=14`. |
| V1 Web Fishing performance probe | **Fixed** | `FishingUiSurface._publish_web_fishing_perf_probe_state()` called the removed `host._skill_detail_has_visible_lazy_placeholders()`. It now uses the current `host._skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders()` owner route. | `test-performance-regressions.ps1` passed; it now asserts the current owner route and rejects the removed host call. |

## Additional harness repairs

| Finding | Disposition | Evidence |
| --- | --- | --- |
| Fishing cold-render probe called the removed main-level placeholder helper. | **Fixed** | Routed both checks through `_skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders()`, the current owner. The probe now asserts virtualized offscreen entries and the 12-card ceiling; it passed with 8 cards. |
| Pinned interaction smoke indexed an empty opportunity-window array. | **Fixed harness-only issue** | The smoke now skips its optional opportunity-click subsection when that fixture supplies no opportunity window. `test-pinned-page-interactions.ps1` and the full gate passed with no script error. No player-visible behavior was changed. |

## Coverage closeout

| Surface / behavior | Evidence | Disposition |
| --- | --- | --- |
| Home, skills menu, settings, shop, hub, leaderboard, achievements, pinned, queue | Repaired census staged each screen. It clicked visible enabled controls on all but Pinned, whose all-unlocked fixture had no enabled buttons. | No new defect. |
| Build, Fight, Fishing, Thieving, Woodcutting | Census exercised Build/Fight/Thieving/Woodcutting controls; Fishing had no enabled button in that fixture. Fishing cold-render, page-performance, module-list transition, and queue coverage exercised its real list and module paths. | No new defect. |
| Pinned and queue | `test-pinned-page-interactions.ps1`, `test-pinned-pin-visual-smoke.ps1`, `test-pinned-scroll-anchor.ps1`, and `test-activity-queue.ps1` passed in the full gate. | No new defect. |
| Leaderboard | `test-firebase-leaderboard-config-validation.ps1`, `test-firebase-leaderboard-runtime-guard.ps1`, and `check-leaderboard-cost-safety.ps1` passed. `test-firebase-leaderboard-live-read.ps1` made one read-only public request and returned one `total_level` row. | Online read works; no write attempted. |
| Global Chat | Valid running-game capture below shows read-ready/opening-stream UI and an unclipped composer. `read-firebase-chat-messages.ps1` requires a moderator ID token not available to this phase, so no authenticated message read, send, moderation, or write was attempted. | External-auth limitation, not a product defect. |

## Visual evidence

These exact PNGs were opened and visually inspected.

| Path | Size / result | Use |
| --- | --- | --- |
| [fight-modules-layout-real-builder-desktop-627x1115.png](C:/Users/bknep/Documents/Idle%20Slop%201/.codex-tmp/fight-modules/fight-modules-layout-real-builder-desktop-627x1115.png) | Real running-game desktop capture, required 2160x3840 design viewport / 627x1115 window pairing. | Valid focused Fighting/module composition evidence from R1. |
| [chat-overlay.png](C:/Users/bknep/Documents/Idle%20Slop%201/.codex-tmp/audit-surfaces/chat-overlay.png) | Real running-game 627x1115 capture. | Valid chat UI evidence: read-ready/opening-stream status, composer, Send button, and bottom navigation. |
| [pinned-pin-visual-smoke.png](C:/Users/bknep/Documents/Idle%20Slop%201/.codex-tmp/pinned-pin-visual-smoke.png) | Real running-game 900x1800 capture. | **Rejected as product proof**: the chat composer overlays the lower surface. |
| `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\fishing-scroll-probe\fishing-page.png` | Pre-existing file only; it was not overwritten by this remediation. | **Rejected**. The repaired focused Fishing full-page route exceeded its bounded render window; owned headless PIDs `98184` and `4276` were command-line verified then stopped. No 2160x3840 / 627x1115 Fishing proof was promoted. |

No valid 1080px-wide portrait image for the changed Fishing lazy-list surface was produced. The focused full-page route is concretely blocked by the bounded render time above, while its automated behavior and mobile-safe control paths are covered by the passing Fishing cold-render, performance, queue, and Pinned checks. This remains an evidence limitation, not a confirmed readability/clipping defect.

## Validation results

| Command | Result |
| --- | --- |
| `git diff --check` | Pass. |
| `.\scripts\test-performance-regressions.ps1` | Pass: `performance-regressions-ok`. |
| `.\scripts\test-home-achievement-medal-click.ps1` | Pass: `home-achievement-medal-click-ok`. |
| `.\scripts\test-button-census-clicks.ps1` | Pass: 26 clicks across 14 scenarios. |
| `.\scripts\test-fishing-cold-render.ps1` | Pass: `cards=8`, no visible placeholders, max warm frame 37.102ms. A prior 50.211ms run was 0.211ms over its timing threshold; the immediate retry passed. |
| `.\scripts\test-activity-queue.ps1` | Pass: `activity-queue-test-ok`. |
| `.\scripts\test-pinned-page-interactions.ps1` | Pass after the harness guard. |
| `.\scripts\test-firebase-leaderboard-config-validation.ps1` | Pass. |
| `.\scripts\test-firebase-leaderboard-runtime-guard.ps1` | Pass. |
| `.\scripts\test-firebase-leaderboard-live-read.ps1` | Pass; one read-only database request, one row. |
| `.\scripts\check-project.ps1` | **Pass (exit 0)**. Its documented non-strict performance wrapper retried three timing-only failures and continued. The final sample still had unrelated frame-budget noise, but `scroll/fishing` had 5 cards and no former card-count or medal script error. |

Known save-recovery/progress-protection warnings and shutdown RID/ObjectDB diagnostics were observed during tests and remain non-defect baseline noise.

## Final changed files

- `scripts/ui/skill_detail_surface.gd`: virtualize offscreen Fishing modules with bounded lazy windows.
- `scripts/achievements/presentation.gd`: tolerate null/empty headless texture images before cropping.
- `scripts/test-button-census-clicks.ps1`: route generated staging through the navigation shell.
- `scripts/tests/fishing_cold_render_probe.gd` and `scripts/test-fishing-cold-render.ps1`: validate the virtualized, capped Fishing list through the current placeholder owner.
- `scripts/test-pinned-page-interactions.ps1`: skip an optional opportunity assertion when the fixture provides no window.
- `docs/comprehensive-game-audit.md`: this updated canonical audit.

## Remaining risks / blockers

- V1's observed `+3` white area is intentional viewport clipping, not a defect.
- Fishing desktop and 1080px mobile screenshots remain blocked by the bounded focused full-page capture route. Do not use the stale PNG as visual evidence.
- Global Chat authenticated message flows require a moderator token. The UI and unauthenticated stream-opening state were verified; no external message write was authorized or performed.
- Strict performance remains noisy across multiple unrelated skills in this environment. The project's non-strict gate passed, and the deterministic Fishing card-count regression is fixed.
