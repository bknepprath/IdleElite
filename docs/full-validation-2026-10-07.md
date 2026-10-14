# Full project validation — 7 October 2026

All 39 named checks in `scripts/check-project.ps1` passed, along with startup smoke and the expanded Ham feedback regressions. The strict skills-page performance test failed. Physical Samsung validation remains blocked because ADB reports no connected devices.

The initial suite stopped at an outdated 1080p migration contract. That contract still required compact XP skill codes and an obsolete bonus column. It now checks the approved full skill names and wrapping across the module width. The existing info-glyph exception also accepts the reviewed 30px fishing “i” icon; fixtures confirm that ordinary 30px button text remains rejected. Production UI was unchanged in this test pass.

After the contract passed, every remaining test ran in an isolated process. Two leaderboard tests initially failed because the orchestration's global offline flag bypassed their simulated sign-in branches. Both passed when rerun without that flag. These fixtures use fake credentials and remain outside the scene tree, preventing network requests.

## Results

| Coverage | Result |
| --- | --- |
| Startup, assets, activity database, generated files, UI boundaries, rendering contracts | Pass |
| Save normalization, corruption recovery, legacy migration, lifecycle persistence | Pass |
| Tutorial, stamina feedback, scrolling layout, fresh-save/first/adjacent swipes | Pass |
| Medal interactions and cleanup, activity geometry, module transitions | Pass |
| Queue, pinned activity interactions, pin appearance, scroll anchors | Pass |
| Online identity guards, profile backfill, leaderboard guards, sync, fresh start | Pass with corrected test environment |
| Crash-report recovery, crash audit, repeated-navigation resource lifetime | Pass |
| Ham feedback: upgrades, persistence, offline rewards, berries, missions, XP help | Pass |
| Strict skills-page frame-time checks | Fail |
| Physical Samsung rendering, touch, background/resume | Blocked: no connected device |

## Strict timing failures

Measured by the headless test, not physical-device frame rates:

- Idle Thieving p99: 4.001 ms against 4 ms.
- Idle Building p99: 4.195 ms against 4 ms; maximum 12.687 ms against 12 ms.
- Thieving scroll maximum: 22.363 ms against 22 ms.
- Fighting scroll maximum: 63.833 ms against 22 ms.
- Woodcutting scroll p99: 27.564 ms against 16.667 ms; maximum 40.508 ms against 22 ms; 22/210 samples exceeded 16.667 ms.
- Building swipe maximum: 66.499 ms against 40 ms; 18/552 samples exceeded the 8.334 ms budget.

The performance run reported shutdown resource warnings. The separate repeated-navigation lifetime check passed. No timing thresholds were weakened, no rendering configuration was changed, and no agent-owned Godot process remained.

## Evidence

- Initial run: `.codex-tmp/full-validation-2026-10-07.log`
- Per-test results and final rerun status: `.codex-tmp/full-validation-results/results.json`
- Individual logs: `.codex-tmp/full-validation-results/`
- Before/after worktree status: `.codex-tmp/tests-before-status.txt`, `.codex-tmp/tests-after-status.txt`
