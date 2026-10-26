# Ham OSRS feedback audit, October 21, 2026

## Scope and status

Reviewed the Ham OSRS Discord DM from the first game invitation on October 4 through the latest messages on October 21. Feedback was read in the logged-in Discord web client. No messages were sent.

Changes are in the active 1080p checkout at `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`. The parent checkout is archived. Existing unrelated changes were preserved. This work is implemented and desktop-tested, but has not been packaged, uploaded or installed on a phone. Physical Samsung rendering acceptance remains required before a release.

## Feedback coverage

| Report | Result and evidence |
| --- | --- |
| Resting missions take too many repetitions (October 4/6) | Already addressed: recovery assignments use 25% of ordinary mission repetitions. Existing assignments migrate once, preserving proportional progress. Verified by `test-feedback-balance.ps1`. |
| Fishing starts slowly; request for an XP-only option | Practice Pool already unlocks at Fishing level 2, costs no stamina and awards XP without fish. Verified live, offline and across fishing tools by `test-feedback-balance.ps1`. |
| Arena missions count waves instead of individual kills | Already addressed: individual chicken kills advance the matching mission once per kill. Stale arena instances cannot advance a different activity. Verified by `test-ham-feedback.ps1`. |
| Hub upgrades depend on Building and softwood, with long gaps | Current hub includes skill-specific upgrade requirements, the woodcutting totem and fighting display, and later hardwood costs. Existing purchase, level, material and save tests passed. Further progression expansion remains a design suggestion. |
| Activity/stat explanations are cut off | Existing module help fixes retained. Current recovery explanation was shortened to its actual stamina amount and target. New raw screenshots show it fully above the bottom controls. |
| Skills-menu scrolling activates activities; mission board obscures the fourth slot | Existing input/layout fixes retained. Ham reported these resolved in the October 15 follow-up. The current board has four readable slots; the production capture and mission-board test validate it. |
| Boat capacity text clips; fishing tools are unclear | Existing tool descriptions and capacity layout retained. Ham reported them resolved on October 15. |
| Fish counter shows 1M before a 1M purchase is affordable (October 9) | Fixed inventory formatting to floor instead of round upward. 999,999 fish displays 999K; 1,000,000 displays 1M. Purchase rules are unchanged. Regression assertions and a raw game screenshot verify the boundary. |
| Fishing boost taps cancel activity; resting boost windows behave incorrectly (October 11/15) | Existing input fixes retained; Ham reported the 0.7 behavior fixed on October 19. Earlier feedback and project interaction regressions passed. |
| Arena medals are hidden and medal-table targeting is difficult | Existing arena exclusion from ordinary mastery totals and medal lookup fixes retained. Medal-total and buff-lookup tests passed. Regular activity medal taps now directly open the compact bonus rows. |
| Stamina appears above maximum after candy (October 19) | Intentional candy overflow, represented by the candy effect. No stamina or save data was removed to conceal it. Resting activities restore their declared target; some target the lowest stamina percentage rather than their own skill. The help now states that target. |
| Resting missions do not restore stamina (October 21) | Found and fixed the offline completion path omitting `RecoveryModules.apply`. Every recovery activity was exercised live and offline, with and without a matching mission: 40 combinations, no failures. Restoration remains capped by the existing stamina rules. |
| Finishing a mission resets another mission's replacement wait (October 21) | Fixed with one saved absolute deadline per waiting slot. Completing another mission preserves earlier deadlines; only expired slots refill. Old shared-timer saves migrate without extending the old deadline, including when offline completion occurs before the first board sync. Regression tests and the board screenshot show separate countdowns. |
| Names, illustrations and supporting skill XP do not agree | Renamed the display names to “Build a Storm Shelter” and “Spar with the Living Tree” to match their illustrations and combined skill use. Public action IDs, saved progress, resource gates and XP rewards remain compatible. |
| Several recovery activities reuse unrelated portraits or show combat effects | Added eighteen distinct resting portraits. Fighting rest cards use the calm farm background; Thieving rest cards use the quiet market lane. The shipwright activity now has a closed lockbox and key portrait. |
| Pictures extend beyond their white frames | Fixed authored portrait boxes and rounded masks in regular and compact cards. Deferred resizing avoids Godot clamping new sizes to the prior cached minimum. All nineteen changed portraits passed bounds checks and visual review in the real main scene. |
| Weapons, armor, rare loot, higher level caps, dual training and another skill | Recorded as feature suggestions. These systems are not implemented by this bug-fix pass. |

## Requested bonus panels

Tier reward cards now use two compact rows: REWARD and its percentage, then the stat logo beside the target tier. Accuracy, stamina and time use their corresponding existing logos. Tier 1 and Tier 3 were opened through actual game input and captured.

Regular activity medal taps open the local medal bonus rows. “Nearby medals” is now “Neighbors.” The local panel omits the “All activities” and “All skills: maximum stamina” summaries; their actual global bonuses are preserved. The panel shows the applied capped neighbor stamina/time reductions. Native fishing-area medals retain their existing interaction.

## Success balance

The authoritative database defines `global_rules.activity_success_curve` with start 90 and ceiling 99.5. Ordinary non-Thieving activity chances above 90 use:

`90 + 9.5 * (1 - exp(-(nominal - 90) / 9.5))`

| Nominal chance | Effective chance |
| --- | --- |
| 90% | 90% |
| 95% | 93.89% |
| 100% | 96.18% |
| 105% | 97.54% |
| 110% | 98.34% |
| 120% | 99.10% |

Bonuses beyond nominal 100 still contribute. Lower chances are unchanged. Thieving retains its exact old pre-Barn and final clamps, tested for every Thieving activity at four medal states and two Barn states. Recovery, passive, convergence and starter guarantees retain their special rules. Fishing catch attempts and Practice Pool use the shared curve while retaining their distinct tool/reward rules.

## Validation

- `scripts/test-ham-oct21.ps1`: passed; `ham-oct21-regressions recovery_cases=40 failures=[]`.
- `scripts/test-ham-oct21.ps1 -VisibleGame`: passed; `ham-oct21-capture failures=[]`. Muted with Dummy audio and isolated user data; online requests and ordinary save writes disabled.
- `scripts/test-ham-feedback.ps1` and `scripts/test-feedback-balance.ps1`: passed.
- `scripts/test-mission-board.ps1`: passed after updating its state-reset fixture for per-slot deadlines.
- `scripts/tests/first_session_input.gd`: passed mouse/touch targets at three window sizes and drag-to-tap recovery.
- `scripts/capture-screen-audit.ps1`: completed the required 14-screen capture pass; all PNGs are 1080x1920. Targeted UI acceptance uses the 27 production-UI captures below.
- `scripts/check-project.ps1`: passed, exit 0, including activity geometry, save hardening, lifecycle, queues, swipes, tier scrolling and performance checks. The suite emits its existing certificate-store/shutdown diagnostics and detached HTTP-request fixture messages.
- `scripts/check-activity-database-contracts.ps1`: passed.
- `scripts/audit-activity-database.ps1`: five skills, 173 activities, zero missing assets. Existing balance warnings remain.
- Raw final screenshots: 27 PNGs, each 1080x1920. SHA-256 values and dimensions are recorded in `outputs/verification/ham-oct21/capture-manifest.json`.
- Android graphics configuration was not changed. Physical-phone validation is outstanding; no release build was made.

## Artwork files

Prompt, anchors and extraction details: [ham-oct21-prompts.md](../art/ham-oct21-prompts.md).

All paths below are relative to the active checkout:

| Skill | Final runtime PNG |
| --- | --- |
| Fighting | `assets/content/fight/actions/catch-breath-between-rounds.png` |
| Fighting | `assets/content/fight/actions/shake-out-the-gloves.png` |
| Fighting | `assets/content/fight/actions/ice-the-bruises.png` |
| Fighting | `assets/content/fight/actions/slow-shadow-boxing.png` |
| Thieving | `assets/content/thieving/actions/count-the-coins.png` |
| Thieving | `assets/content/thieving/actions/hide-in-plain-sight.png` |
| Thieving | `assets/content/thieving/actions/case-the-quiet-corner.png` |
| Thieving | `assets/content/thieving/actions/lay-low-until-morning.png` |
| Thieving | `assets/content/thieving/actions/nap-behind-the-market-stall.png` |
| Building | `assets/content/build/actions/sit-on-the-toolbox.png` |
| Building | `assets/content/build/actions/sweep-the-worksite.png` |
| Building | `assets/content/build/actions/inspect-the-blueprints-again.png` |
| Building | `assets/content/build/actions/measure-twice-again.png` |
| Woodcutting | `assets/content/woodcutting/actions/lean-on-the-axe.png` |
| Woodcutting | `assets/content/woodcutting/actions/snack-on-trail-mix.png` |
| Woodcutting | `assets/content/woodcutting/actions/oil-the-axe-handle.png` |
| Woodcutting | `assets/content/woodcutting/actions/stretch-the-splinters-out.png` |
| Woodcutting | `assets/content/woodcutting/actions/rest-under-the-stump.png` |
| Thieving | `assets/content/thieving/actions/shipwrights-lockbox.png` |

## Raw game screenshots

These are unmodified viewport PNGs from the current production main scene, reached through its UI. Each target control remains in its production hierarchy. Test state unlocks the necessary activities. No isolated UI render, crop, resize or composition was used.



![tier 1 compact](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/tier-1-compact.png>)

![tier 3 compact](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/tier-3-compact.png>)

![medal compact](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/medal-compact.png>)

![build weatherproof weather](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/build-weatherproof-weather.png>)

![case the quiet corner](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/case-the-quiet-corner.png>)

![catch breath between rounds](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/catch-breath-between-rounds.png>)

![count the coins](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/count-the-coins.png>)

![crack the shipwrights lockbox](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/crack-the-shipwrights-lockbox.png>)

![fell tree that remembers you](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/fell-tree-that-remembers-you.png>)

![fish count below million](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/fish-count-below-million.png>)

![hide in plain sight](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/hide-in-plain-sight.png>)

![ice the bruises](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/ice-the-bruises.png>)

![independent mission timers](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/independent-mission-timers.png>)

![inspect the blueprints again](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/inspect-the-blueprints-again.png>)

![lay low until morning](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/lay-low-until-morning.png>)

![lean on the axe](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/lean-on-the-axe.png>)

![measure twice again](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/measure-twice-again.png>)

![nap behind the market stall](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/nap-behind-the-market-stall.png>)

![oil the axe handle](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/oil-the-axe-handle.png>)

![recovery target](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/recovery-target.png>)

![rest under the stump](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/rest-under-the-stump.png>)

![shake out the gloves](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/shake-out-the-gloves.png>)

![sit on the toolbox](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/sit-on-the-toolbox.png>)

![slow shadow boxing](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/slow-shadow-boxing.png>)

![snack on trail mix](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/snack-on-trail-mix.png>)

![stretch the splinters out](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/stretch-the-splinters-out.png>)

![sweep the worksite](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/ham-oct21/sweep-the-worksite.png>)
