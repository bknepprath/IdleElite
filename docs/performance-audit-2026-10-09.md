# Scroll and latency audit, October 9, 2026

## Change

Post-tutorial Push-Ups completions no longer synchronously write a complete save every time. They mark progress dirty for the existing autosave and lifecycle-save paths. Tutorial completions still save immediately, and completion counters and the first-module release behavior are preserved.

The completion trace identified a Fighting completion taking about 64 ms in the tip-recording/UI phase, while the UI trace accounted for about 5 ms. The tip recorder was still forcing a save after onboarding. The new persistence regression test checks one immediate tutorial save, 100 subsequent Push-Ups completions without additional immediate saves, another activity completion, and preserved counters.

## Method and limits

Godot 4.7.1, Windows desktop, safe runner, sequential headless runs. These measurements cover CPU-side work and frame scheduling, not GPU rendering or physical-phone frame rates. The strict skills benchmark runs activities while scrolling and swiping. Its timing limits were not changed.

The new `scripts/test-screen-performance.ps1` diagnostic boots the production main scene and samples two passes through menu, hub, shop, achievements, settings, a 16-item queue, 16 pinned activities, an offline leaderboard, profile, and chat with 60 local test messages. It records screen construction time, idle and scroll samples, p99, maximum frame intervals, and intervals over 16.667 ms. Saves and online requests are disabled in this diagnostic only. Overlay samples are scoped to the overlay, so profile does not accidentally scroll the menu behind it. Screens without a scroll range report `scroll_sampled: false`.

The diagnostic's success marker means the audit completed without runtime errors; it is not a performance acceptance gate. Raw output is saved in `.codex-tmp/screen-performance.json`. No test messages are sent. No user saves, prices, rendering settings, or assets were changed.

## Validation

| Check | Result |
| --- | --- |
| Activity completion persistence regression | Pass |
| Save lifecycle guard | Pass |
| Pinned scroll anchor | Pass |
| Hidden preview / scroll-gap regression | Pass |
| Resource lifetime, four cycles through 16 routes | Pass |
| Broader screen diagnostic, two passes | Completed |
| Strict skills performance | **Fail** |

Resource lifetime finished each cycle with 439 nodes. Texture counts were 13, 10, 10, 10. Object counts increased by two per cycle (3092 to 3098), within the existing gate; this is not proof of zero object leakage over an arbitrarily long session.

## Remaining timing failures

After the save fix, all five idle skill samples passed the strict timing limits. Scrolling still failed. The table records that run, not a promised improvement relative to the baseline:

| Skill scroll | p99 interval | Maximum interval | Intervals over 16.667 ms / 210 |
| --- | ---: | ---: | ---: |
| Thieving | 12.54 ms | 23.99 ms | 1 |
| Building | 17.88 ms | 26.24 ms | 4 |
| Fighting | 23.29 ms | 24.50 ms | 15 |
| Fishing | 20.44 ms | 25.03 ms | 10 |
| Woodcutting | 22.28 ms | 96.11 ms | 15 |

The ordinary swipe sample also failed: p99 16.95 ms, maximum 25.31 ms, seven intervals over 16.667 ms. Rapid swipes passed their existing limits. No settled visible placeholders or card-count violations were reported.

Results varied substantially between runs. The baseline had fewer timing failures in several skills. Removing the unnecessary save is behaviorally verified, but these runs do not establish a general frame-rate improvement. The remaining 96 ms Woodcutting interval has not been attributed conclusively.

## Other screens

Selected results from the corrected broader diagnostic:

| Screen | First / second construction time | First / second scroll p99 | First / second scroll maximum |
| --- | ---: | ---: | ---: |
| Menu | 38.46 / 27.89 ms | 25.87 / 10.27 ms | 30.43 / 15.65 ms |
| Queue, 16 activities | 251.75 / 101.40 ms | 27.35 / 3.92 ms | 29.01 / 10.51 ms |
| Pinned, 16 activities | 218.68 / 107.43 ms | 28.66 / 4.51 ms | 47.56 / 11.93 ms |
| Offline leaderboard | 37.19 / 24.66 ms | 5.09 / 0.53 ms | 10.62 / 0.58 ms |
| Chat, 60 messages | 98.46 / 7.01 ms | 10.57 / 4.95 ms | 11.99 / 8.18 ms |

The first pass also had intermittent stalls on several non-scrolling screens. Their substantially faster second pass means cold work and host scheduling must be separated before attributing every interval to a specific control. The offline leaderboard does not cover a populated live leaderboard or network latency.

## Next optimization targets

1. **Queue and pinned entry:** both synchronously construct every activity card. Earlier runs also showed roughly 90–140 ms openings. Use bounded construction or reuse without introducing blank cards, changing scroll height, or breaking pin/unpin anchors. Test navigation cancellation and long lists.
2. **Lazy skill cards:** trace logs put many slow frames in card construction/mounting. Some Fighting cards take 15–26 ms to construct. Profile the construction phases and separate expensive setup while retaining existing cache limits and placeholder checks.
3. **Save latency:** the unnecessary completion save is fixed, but scheduled saves and activity-start saves remain synchronous. Profile them separately. Any scheduling change must retain bounded save latency, failure recovery, and immediate lifecycle saves.
4. **Device validation:** repeat touch scrolling, rapid skill swipes, long lists, and activity completions on the physical Samsung phone with the current viewport configuration. Headless results cannot clear the Android rendering gate.

Raw logs: `.codex-tmp/performance-audit-2026-10-09-before.log`, `.codex-tmp/performance-completion-profile.log`, `.codex-tmp/performance-audit-after-save-fix.log`, `.codex-tmp/screen-performance-scoped.log`, `.codex-tmp/performance-resource-audit.log`, and `.codex-tmp/audit-*.log`.

## Follow-up optimization pass

Implemented after the audit:

- Cache the shared reward-achievement snapshot once per stat-cache version. Different stats and skills reuse it; progression invalidation refreshes it.
- Skip mastery lookups for activities too far away to contribute a medal bonus. The tested time, accuracy, and stamina calculations need only 3, 5, and 8 contributing-neighbor lookups in a 50-activity fixture.
- Coalesce deferred berry-badge refreshes. Building several cards queues one group refresh instead of one complete group scan per card.
- Query the sparse tutorial-note groups instead of recursively walking every card's labels, borders, and icons during scroll-bound and blank-page checks. Detached controls retain the recursive path, and mounted controls retain the original Control-only ancestry behavior.
- Let staged card work finish before automatic blank-page repair can rebuild the list.
- Queue ordinary completion stat refreshes when a card is being built in that frame. The regular frame update consumes the request when card construction is idle. Reward calculations and feedback still happen immediately; bonus-change ceremonies retain the immediate refresh.
- Improve the benchmark diagnostics to retain the worst eight frame samples instead of the first eight slow samples, including the main-process frame index. Performance thresholds are unchanged.

The completion trace measured approximately 5.5 ms in Thieving's forced UI refresh, on top of reward work and a card mount. After scheduling that refresh, the measured completion frame dropped from 25.64 ms to 16.22 ms. In that run all five skill-scroll samples passed; the swipe sample missed the stricter 120 Hz count by one frame (11 intervals above 8.334 ms, limit 10). This is a measured run, not a guarantee of identical timings on every run or device.

Final broader screen diagnostic, 16 cards per list:

| Screen | First / second construction | First / second scroll p99 | First / second scroll maximum |
| --- | ---: | ---: | ---: |
| Queue | 75.27 / 83.13 ms | 2.52 / 3.18 ms | 7.80 / 8.75 ms |
| Pinned | 82.45 / 85.38 ms | 2.99 / 3.92 ms | 10.70 / 13.54 ms |

Queue and pinned construction is faster in these measurements but still happens in one synchronous batch. Bounded list construction or virtualization remains the next larger change; it needs its own navigation-cancellation, long-list, scroll-anchor, and real-game visual checks.

Functional validation passed after the production changes: feedback/progression tests, cached-versus-full reward calculations across empty/mixed/maximum mastery, neighboring-medal contribution tests, tutorial-group membership changes, queued-versus-instant refresh behavior, tutorial start scrolling, pinned scroll anchors, hidden preview scroll gaps, and four resource-lifetime cycles. The resource audit retained 439 nodes and the same bounded texture counts. The tutorial harness still logs its known shutdown resource warnings despite its successful behavioral result.

**Final repeatability status: failed on run 1 of 3; runs 2 and 3 were not started.** Thieving, Building, and Fishing scroll samples passed, but Fighting and Woodcutting scrolling, Woodcutting idle, and the ordinary swipe sample failed timing limits. Final Fighting scroll p99/max was 18.46/26.60 ms; Woodcutting was 17.46/59.77 ms. Thieving's maximum remained below one 60 Hz frame at 14.92 ms. The earlier all-scroll pass is therefore not a repeatable overall acceptance result. Further work should target bounded card construction, completion work, and save latency; these changes must not be described as eliminating all lag.

Follow-up logs: `.codex-tmp/perf-fix-feedback-final.log`, `.codex-tmp/perf-fix-completion-repeat.log`, `.codex-tmp/perf-fix-final-screens.log`, `.codex-tmp/perf-fix-acceptance-repeat.log`, and `.codex-tmp/perf-fix-*-scroll*.log` / `.codex-tmp/perf-fix-performance-resource-lifetime.log`. Temporary card/completion profiling probes were removed from production source. Physical Samsung validation remains outstanding.
