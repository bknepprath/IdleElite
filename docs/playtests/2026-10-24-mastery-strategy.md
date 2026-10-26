# Mastery strategy and Building cadence

Implemented in the current source worktree; no export or deployment

## Success progression

Earlier medals now contribute accuracy to the next three eligible activities: 0.5, 0.3 and 0.1 percentage points per medal. Existing later-neighbor support and next-tier Bronze rewards remain intact. No diminishing-returns curve or hard medal gate was added.

Individually tuned opening base rates across five skills. These runtime examples exclude unrelated account bonuses and use hands for Fishing:

| Skill | First activity with two opening Bronzes | Second with two opening Silvers | Third with three opening Silvers | Third with Silver / Gold / Silver |
| --- | --- | --- | --- | --- |
| Fighting | 100% | 100% | 99.8% | 100% |
| Building | 100% | 100% | 99.7% | 100% |
| Thieving | 100% | 100% | 99.6% | 100% |
| Woodcutting | 100% | 100% | 99.5% | 100% |
| Fishing | 100% | 100% | 99.8% | 100% |

Own-activity medals now affect tool-based Fishing as they do other activities. Shallows and Rocks hand-catching bases come from the activity database. Other tool bases and roles remain unchanged.

With Bronze on every eligible activity, the number of level-15+ activities still below 100% is 18/22 in Fighting, 20/24 in Building, 21/25 in Thieving, 21/25 in Woodcutting and 23/23 in Fishing with hands. Starter medals have no neighbor-accuracy contribution beyond their three-activity forward range. Previously earned account bonuses can still complete rates earlier.

## Building

All 29 ordinary positive-stamina activities double stamina, XP and cycle time. Mastery XP, unlock-resource drops, Wisdom and cross-skill XP also double per completion. Recovery actions, saved progress and project targets remain unchanged. Base rewards per second and per stamina are preserved; actions and mission counts still count actual completions.

Stack Bricks now uses 2 stamina, awards 2 XP and takes 2.98 seconds. Hammer Nails awards 6 XP for 2 stamina in 3.42 seconds. Patch Fence awards 8 XP for 2 stamina in 3.64 seconds.

## Verification

- Activity database contracts and structural/assets audit passed
- Focused five-skill medal profiles, later-tier saturation and all 29 Building ratio checks passed
- HAM progression, recovery, save and neighboring-medal regression checks passed
- Production resource progression, offline awards, migration and save round-trip checks passed after updating Building yield fixtures
- Raw production-main-scene 1080 × 1920 captures show the changed Building values and Fighting's 99.8% Silver case
- Fishing tool economics, simulated long-run rates, live/offline rewards and actual tool selection passed
- UI boundary and test-harness contracts passed

The Fishing suite exposed two existing issues following the corner relocation: wider estimates could overlap the picker, and a rate preview could stop fading when its wall-clock update window expired during a slow frame. The picker now clears the rate panel, and visible unfinished previews keep receiving updates. Production before/transition/settled captures verify dismissal. The test also now dismisses the seasonal greeting before navigating and compares its historical economy fixture at current success rates.

Additional raw evidence: `wallet-rate-clearance.png`, `wallet-before-dismissal.png`, `wallet-fade-transition.png`, `wallet-fade-settled.png` in the same verification folder

Evidence: `outputs/verification/medal-strategy-oct24/runtime-profiles.json`, `building-base-cadence.png`, `third-activity-silver.png`, `capture-result.json`

Reusable tests: `scripts/tests/medal_strategy_oct24.gd`, `scripts/tests/medal_strategy_capture.gd`, `scripts/tests/progression_prototype.gd`. The prior balance fixture is `scripts/tests/fixtures/medal-strategy-before-2026-10-24.json`.
