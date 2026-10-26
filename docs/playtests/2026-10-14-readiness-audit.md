# October 14 readiness audit

Status: changes implemented and tested locally; not release-approved, exported or published.

Authoritative checkout: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`. The checkout already contained substantial progression, construction, desktop and Halloween work. This report distinguishes the audit's changes from that existing work. Halloween implementation was left to the other active chat after Brian confirmed ownership.

## Changes from this audit

- Desktop startup now waits for the final desktop hierarchy to mount before releasing the loading cover. The desktop start operation is idempotent, and a new toolbar starts hidden.
- The bottom ribbon now fades its background and children together. Its previous `self_modulate` fade left its icons fully opaque while its backing appeared. The originally reported double entrance was not reproduced in the baseline fresh/returning tests; this change fixes the observed split fade and removes a startup ordering gap.
- Wrestle Stuck Gate Latch, Saw Planks and Split Firewood each grant 4 primary XP and 2 supporting XP, increased from 4 + 1. The primary rewards, requirements, cycle times, stamina costs and resource contributions are unchanged.
- Reveal covers share their immutable shader while keeping separate material uniforms. This removes repeated shader creation during entrances. It does not establish that scrolling meets the frame budget.
- Runtime asset auditing prunes generated directories before traversing them and avoids repeated filesystem path resolution. One measured run fell from 34.07 seconds to 2.60 seconds. All nine material families' dynamically selected holders, chips and damage states are now checked explicitly.
- Test cleanup avoids requiring CIM access when no Godot processes exist. The safe runner rejects process limits above four. Ownership checks remain required when processes exist.
- Save-hardening and three swipe/tier tests now honor the caller's isolated data directory. The construction unit test waits for production boot before changing test state. Avatar normalization expectations now use the actual portrait count.
- The 1080p contract distinguishes platform-guarded desktop font/scaling overrides from Android code. Android retains viewport stretch and Compatibility rendering. The mobile small-font threshold was not lowered.

Before the separate Halloween ownership was confirmed, an invalid seasonal block in canceled-action processing referenced an undefined `action`; that duplicate block was removed to restore compilation. No further seasonal behavior was changed in this audit.

## Early skill links

| Activity | Existing requirements | Reward now | Expected supporting XP/minute at full speed |
| --- | --- | --- | --- |
| Wrestle Stuck Gate Latch | Fighting 3, Building 2 | Fighting 4, Building 2 | 71.55 |
| Saw Planks | Building 4, Woodcutting 2 | Building 4, Woodcutting 2 | 62.90 |
| Split Firewood | Woodcutting 4, Fishing 3 | Woodcutting 4, Fishing 2 | 74.14 |

These make another skill account for one third of the reward during early combo training, compared with one fifth before. Each cycle pays 20% more total base XP. The intended choice is between advancing one skill directly and preparing the next skill while training the current one.

Rates above use source cycle times and success probabilities. They exclude stamina depletion, input time, crits, streaks and mastery; they are not measured sustained progression rates. Final pacing still needs a fresh-player session.

The live test clicks each actual production card, verifies that it starts, waits for completion, and checks that both skill balances increase. Source data and runtime reward maps agree. A dependency scan found no unavailable resource-source chain at skill caps 5, 10, 20, 50 or 99 among 172 nonseasonal activities. It assumes the required levels and does not prove Wisdom pacing, construction affordability or the absence of every possible progression stall.

## Test results

The initial runtime batch passed 22 of 35 checks. Seven failed checks passed after targeted corrections/rechecks, bringing the current status of those checks to **29/35**. The visible desktop batch passed **12/12**. This is 41 passing scenarios across 47 checks, not a claim that every release gate passes. Repeated executions and diagnostics are not counted as additional scenarios.

Runtime evidence:

- Initial results: `.codex-tmp/audit-2026-10-14/runtime-results.json`.
- Initially passing areas include activity database contracts, UI boundaries, crash contracts, performance-monitor and resource-lifetime checks, stability, save lifecycle, online identity, queues, list transitions, Firepit, progress turnover, adjacent swipes, pinned scrolling/interactions, stamina failure feedback, medal handling and crash recovery.
- Rechecked passes: runtime asset paths, 1080p contracts, save hardening plus v1 migration, first swipe, fresh-save swipes, tier-banner drag/tap/swipe, and buildable modules.
- Save evidence: `save-hardening-recheck.log`; swipe/tier evidence: `recheck-test-*.stdout.log`; construction evidence: `buildable-final.stdout.log`.
- Save tests run against disposable test data, not the player's save. Known headless shutdown resource warnings remain and are not evidence of a leak-free long session.

Visible desktop scenarios, all through the real main scene with preview audio muted:

1. Fresh startup: loading cover, ribbon instance, monotonic fade, stationary position, and common opacity for backing/icons.
2. Returning-save startup: no exposed unfinished desktop hierarchy or portrait ribbon.
3. Three early skill links: actual card input and primary/supporting XP.
4. Opening sequence and Settings reset.
5. Responsive layout at 800×600, 1000×600, 1280×720, 1366×768, 1920×1080, 2560×1440, 3440×1440 and 3840×2160.
6. Focus and reveal behavior.
7. Reveal tips.
8. Corner navigation.
9. Resource contributions and construction blockers.
10. Full-width barriers for all nine materials.
11. Automatic locks in an unfocused visible column.
12. Construction panel: insufficient resources, exact cost, one-time Building XP, persistent built state and later training input.

Desktop evidence: `.codex-tmp/audit-2026-10-14/desktop-results.json` and the adjacent `desktop-*.godot.log` files. These verify existing construction fixes; this audit did not author those fixes.

## Outstanding failures and release gates

| Area | Evidence and next required work |
| --- | --- |
| Scroll performance | Strict CPU frame-budget checks failed twice. Initial scroll p99 was about 17–23 ms; maximum sampled frame work reached 64.5 ms. Idle pages were roughly 1–1.4 ms average. Fishing scrolling, card mounting and rapid navigation need profiling and further optimization. Thresholds were not relaxed. Headless timing does not measure GPU or browser performance. |
| Import policy | Performance resource contract flags the new Halloween images plus the boot illustration and timber/stone barrier atlases. Reconcile intentional image settings with the import policy and validate actual exports. This audit did not rewrite the other chat's import metadata. |
| Save normalization | The original test expected stamina clamped to the normal maximum; Halloween now intentionally preserves candy overfill. Avatar assertions were updated, but seasonal normalization acceptance belongs with the Halloween work. Do not treat this gate as passed. |
| Recovery geometry | Test expects normal-card height, a particular bottom radius and the old wide U rail. Inspect the intended recovery treatment and revise either implementation or expectations with real-game portrait proof. |
| Combo geometry | Test expects one continuous empty combo track; current design uses two skill colors. Update the test only after confirming that design expectation. |
| Tutorial navigation | Old test expects every ribbon button visible immediately. Current opening stages feature reveals. Reconcile the portrait tutorial expectation separately; passing desktop introduction checks do not clear it. |
| Browser release | Current source has not passed an actual itch.io embed/fullscreen/resize/save/audio-tab test. Native desktop at web dimensions is not browser acceptance. |
| Android release | Physical Samsung preview acceptance remains required. No stretch/renderer settings changed, and no Android release was produced. |
| Long-session stability | Final 30-minute session, live profile/chat/high-score round trips, offline/resume and cloud conflict checks remain required. Short tests do not replace these. |
| Halloween | Separate active implementation; event end time, final art/balance and seasonal release checks remain outside this audit's acceptance. |

## Image resolution findings

Twenty-eight damage frames across iron, bronze, silver, gold, titanium, platinum and obsidian are each 418×220. Their authored portrait draw box is approximately 1062 px wide, a 2.54× enlargement. These are the clearest candidates for higher-resolution regeneration. Preserve the approved composition, canonical canvas and ground anchor across all four states; do not compensate with per-frame alpha-bound scaling.

Generate new masters at least as wide as the largest supported draw box, then compare all damage transitions in the real game at portrait and desktop dimensions. Enlarging the existing PNGs would not recover detail. No replacement artwork was generated or accepted in this audit.

Detailed inventory and resource graph: `.codex-tmp/audit-2026-10-14/progression-and-resolution.json`. Reproduce with `python scripts/audit-early-progression.py`.

## Visual evidence

Raw 1920×1080 viewport captures:

- Ribbon before/transition/settled: `.codex-tmp/audit-2026-10-14/final-startup_ribbon/ribbon-before.png`, `ribbon-transition.png`, `ribbon-settled.png`.
- Early combos: `.codex-tmp/desktop-responsive/early-link-wrestle-stuck-gate-latch.png`, `early-link-saw-planks.png`, `early-link-split-firewood.png`.

All are current production-main-scene captures reached through actual UI input. They are not cropped, scaled or composited. Test-state setup supplies prerequisites without changing the production hierarchy.

## Follow-up: unlock layout stability

Brian reported modules disappearing and pushing other UI around. The real-game reproducer `scripts/tests/unlock_layout_stability.gd` confirmed that resource barrier completion destroyed the old layout row in both landscape and portrait. A first implementation retaining the row also exposed an entrance replay: the row moved about 16.8 px and became translucent because the layout snapshot did not recognize project rows without module keys.

Final implementation preserves the row and reserved height while mounting the ordinary activity inside it. Portrait completion uses in-place list reconciliation. Snapshot identity survives the project-to-activity key change, and visible transition initialization runs at frame_pre_draw rather than after an exposed frame. No asset, renderer, viewport or seasonal behavior changes were made.

The final run reports zero lost-slot frames, zero translucent-slot frames and 0 px maximum slot movement at both 1920x1080 and 1080x1920. Actual blocker clicks navigate to Split Firewood; actual activity input supplies the Plans to clear Repair Small Shack. The normal level-six padlock remains after the resource barrier clears. All seven ribbon feature reveals preserve button rectangles. See `.codex-tmp/unlock-stability-verified.log`.

Related regressions passed: module-list transitions (including sorting, pinning, collapse and insertion), pinned scroll anchors, activity progress turnover, UI boundary, activity UI boundary and crash contracts. Known test shutdown resource warnings remain. These focused checks do not establish that every progression sequence or final platform release is ready.

Raw current screenshots, inspected without resizing or cropping, live at `.codex-tmp/desktop-responsive/unlock-stability-1920-{before,transition,settled}.png` and `unlock-stability-1080-{before,transition,settled}.png`.

Final expanded regression: `.codex-tmp/unlock-stability-neighbours.log` also verifies the existing neighboring rows, reporting `neighbour_changes=0` in both sizes and `UNLOCK_LAYOUT_STABILITY failures=[]`. The repeated real-game automatic-unlock test reports `AUTO_LOCK_ANIMATION failures=[]` in `.codex-tmp/unlock-stability-auto.log`. The later smoothness run below supersedes those screenshot files.

## Follow-up: continuous transitions and interruption handling

The old project panel faded itself away on a timer before the replacement activity existed. It now stays opaque until the actual activity mounts, then fades over that activity for 0.32 seconds. The original barrier remains in the production row during the fade and is freed afterward. Its draw order covers the activity face, title, padlock and pin layers. Resource refreshes during the fade cannot restart it.

The expanded iron-barrier test exposed another height writer: normal card-state updates replaced the retained row height with the shorter card height. This shifted the scrolled column by up to 62 px in portrait. A row-specific height reservation now survives these updates; explicit collapsed-module handling remains separate. Space is normalized when the page is rebuilt, rather than shifting during barrier completion.

Desktop popup visibility used a separate close timer. A close/reopen/close sequence could leave the first timer alive to hide the second animation early. Hiding is now a callback on the current tween, so canceling the tween cancels that callback. The test opens the production Profile via its Chat button before issuing rapid visibility requests through the shared lifecycle API.

| Final check | Result / evidence |
| --- | --- |
| Timber barrier, landscape and portrait | Pass. Zero empty-content frames, lost rows, faded rows, fade reversals and neighboring-row changes. Maximum row movement 0 px. `.codex-tmp/smoothness-handoff-verified.log`. |
| Iron barrier, landscape and portrait | Pass with the same zero counters and 0 px maximum movement. `.codex-tmp/smoothness-tall-handoff.log`. Enable `IDLE_ELITE_TALL_BARRIER_TEST=1` for this variant of `unlock_layout_stability.gd`. |
| Ribbon feature reveals | Seven feature states checked in each barrier run; existing button rectangles stay unchanged. |
| Popup interruption | Pass: no premature hiding or opacity reversal; reopening stays visible after canceled closes. `.codex-tmp/modal-motion-verified.log`. |
| Detail refresh / progression order | Pass. Test now distinguishes resource barriers from action previews and checks barrier insertion retains the current page. `.codex-tmp/detail-refresh-stability.log`. |
| Module-list transitions | Pass on the final isolated-profile rerun. One preceding fresh-profile attempt failed its frame-count boot deadline before exercising transitions. `.codex-tmp/smoothness-module-transitions-final.log`. Known test shutdown resource warnings and rejected regressive fixture saves remain. |
| UI, activity UI and crash contracts | Pass; renderer/stretch settings unchanged. |

Inspected raw before/transition/settled viewport frames are in `.codex-tmp/desktop-responsive/`: `unlock-stability-{1920,1080}-*.png`, `unlock-tall-stability-{1920,1080}-*.png`, and `modal-motion-*.png`. Landscape and modal PNGs are 1920x1080; portrait PNGs are 1080x1920. These checks cover the named transitions, not every game sequence. Browser acceptance, physical Samsung validation, unresolved performance budgets, higher-resolution metal-barrier masters and separate Halloween acceptance remain open.

## Lag follow-up

See [the lag audit](2026-10-14-lag-audit.md) for the measured fixes, 1,008-state unlock comparison, four-cycle resource test, 40 screen samples and real desktop captures. This improves Fishing scrolling substantially but does not clear the complete performance or platform release gates.

