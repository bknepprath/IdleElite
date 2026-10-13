# Game polish validation, October 7, 2026

Worktree: `release/0.6.0`, `.codex-tmp/worktrees/idle-elite-1080p`.

## Changes

- Fishing tool help uses 60 px titles and 52 px body text. Opening help widens the existing tool panel to fit the copy; closing it restores the compact grid. Tool descriptions emphasize practical differences and explicitly state that Practice Pool gives XP without catching fish or using stamina.
- Tool-panel clicks stay within the panel instead of reaching activities underneath it.
- Hub upgrade descriptions show current and next benefits in plain language. Garden shows the total offline duration. Mission Board now includes the next upgrade's benefits.
- Lazy card construction, mounting, and prewarming share a work budget. Non-fishing cards can be constructed before they are mounted. Cleanup remains active during long scrolls to keep the live card count bounded.
- Adjacent skill-page preparation pauses during scrolling/card work and checks that its host still exists after asynchronous waits.
- Unchanged activity stats avoid repeated calculations and label updates. Bonus changes still invalidate the displayed stats.
- Medal counts use a tier histogram instead of scanning every tier for every activity. Activity completion only snapshots global medal unlocks when a medal can change.

## Gameplay and interaction coverage

`scripts/test-game-polish.ps1` runs isolated save fixtures, disables network requests/save writes, and mutes Godot audio. `-VisibleGame` runs the production main scene visibly for raw screenshot verification.

- All six hub modules, all four upgrade tiers: skill requirements, exact wood/fish costs, missing-currency rejection, 20 repeated purchase attempts, delayed bonuses, idempotent construction completion, and maximum-tier rejection.
- Save/restore preserves active activity, partial progress, materials, berries, missions, completed upgrades, and upgrades under construction. Zero elapsed offline time does not award duplicate rewards.
- Empty, mixed, and maximum mastery fixtures: all skill/tier counts match an independent direct count, and fast achievement checks match the complete achievement list.
- Fresh progression uses seed `20261007` and 120 seconds of simulated offline activity. Fighting earns 42 XP, Building 42, Thieving 50, Woodcutting 44, and Fishing 27. Each crosses the 22 XP threshold for level 2. This is a deterministic progression checkpoint, not a measured two-minute player session or a guarantee for every random outcome.
- Mouse/touch activity taps at three window sizes and three positions; dragging must not activate the activity, and the next tap must work.
- All seven fishing-tool help panels; help text must not start an underlying activity; closing help must restore the compact grid.
- Opening activity help preserves the running activity. Starting/expiring an ad bonus updates the cached time value. Switching away and back preserves partial progress.

Final focused run: **passed**, including three open/close cycles each with mouse and touch. Command: `scripts/test-game-polish.ps1 -VisibleGame`. Log: `.codex-tmp/game-polish-complete.log` (`ham-feedback failures=[]`, `INPUT_TEST failures=[]`, `polish-ui failures=[]`, `game-polish-ok`).

The final resource-lifetime, adjacent-page swipe, medal-ceremony cleanup, activity-card geometry, and generated-file hygiene checks also passed. Some headless harnesses still print known shutdown resource warnings; the dedicated resource-lifetime check passed. `git diff --check` passed.

The 39 functional/contract gates in `check-project.ps1` completed during this pass before the strict performance stage failed. That broader run preceded the final medal-count and card-budget refinements; focused checks cover those refinements separately. Log: `.codex-tmp/polish-full-validation.log`.

## Performance remains open

Strict limits were not relaxed. The final strict repeat stopped after run 1 failed, so three consecutive passes have **not** been achieved. These are headless desktop frame-work measurements, not physical-phone frame rates.

| Scenario | p99 | Maximum | Result |
| --- | ---: | ---: | --- |
| Building idle | 5.057 ms | 11.654 ms | Fails 4 ms p99 limit |
| Thieving scroll | 10.622 ms | 21.126 ms | Pass |
| Building scroll | 11.543 ms | 24.468 ms | Fails 22 ms maximum |
| Fighting scroll | 18.229 ms | 20.005 ms | Fails p99 and slow-frame count |
| Fishing scroll | 12.573 ms | 16.258 ms | Pass |
| Woodcutting scroll | 13.850 ms | 16.435 ms | Pass |
| Skill swipes | 7.376 ms | 11.604 ms | Pass |
| Rapid skill swipes | 5.207 ms | 18.862 ms | Pass |

Other idle scenarios passed. Fighting had five of 210 sampled scroll frames above 16.667 ms. No final sample exceeded the live-card limit or left visible placeholders at the end of the scenario. Earlier runs had larger outliers; this does not establish that lag spikes are eliminated. Log: `.codex-tmp/polish-performance-final.log`.

## Visual verification and device limits

Screenshots are raw 1080 × 1920 viewport PNGs from `res://scenes/main.tscn`, reached through the production UI with a deterministic test state and muted preview audio. They are not cropped, resized, or composited. Files are under `.codex-tmp/polish-review/`:

- `hub-barn.png`, `hub-garden.png`, `hub-pond.png`, `hub-mission.png`
- `fishing-hands-help.png`, `fishing-net-help.png`, `fishing-line-help.png`, `fishing-boat-help.png`, `fishing-mirror-help.png`, `fishing-reinforced_rod-help.png`, `fishing-star_rod-help.png`
- `activity-help.png`

ADB returned no attached device. Physical Samsung rendering and sustained performance remain unverified. Rendering configuration and the `viewport` stretch mode were not changed. No Android release was built or published.
