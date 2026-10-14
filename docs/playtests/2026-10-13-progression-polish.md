# Progression polish — 2026-10-13

Source: `codex/progression-070` in the existing `idle-elite-1080p` worktree. Implemented ideas 1, 2, 4, 5 and 6. Idea 3 (new running-activity styling) was excluded. No export, release candidate or release was produced.

## Changes

- XP fractions use XP earned since the current level threshold and XP required for that level. The bar and fraction now describe the same interval. Lifetime totals remain in Progress and at level 99. Saved totals and progression math are unchanged.
- The next locked activity follows the authored progression order, including combo activities. Sorting the displayed list does not choose a different next project. That project keeps the full illustration and stronger frame; later projects use compact panels. Each requirement gets a rail and the active source reports its contribution per successful completion.
- Routine XP has shorter travel and no scale bounce. Normal successes no longer scale the activity art. Existing critical-hit and level-up effects remain.
- Skills navigation remembers focus, scroll positions and expanded details. Explicit project-source navigation takes precedence over remembered focus.
- Resizing and social-panel reflow preserve the visible running skill, or the focused skill if the running skill was already offscreen. Returning to three columns restores the saved column position. Manual carousel navigation clears that preference.

## Verification

`scripts/tests/progression_polish.gd` ran the actual `res://scenes/main.tscn` visibly through `run-godot-safe.ps1`, using Dummy audio, an isolated test profile, disabled saves and disabled network requests. Production activity, stat, project-source and ribbon buttons received actual input. Fixtures set progression state and scroll to virtualized project entries.

Final log: `.codex-tmp/progression-polish.log`, `PROGRESSION_POLISH failures=[]`. No script errors. The test process exited and the process inventory was empty. The fixture grants five eligible bronze medals and asserts that the actual Shop button changes the current screen before testing its return.

Passed: level 6 starts at 15/288 XP; an actual completion advances project work; the active source contribution is shown; source navigation reaches Building; expanded XP details and vertical scroll survive Shop; 1920x1080 to 1280x720 and Chat preserve running Building through three, two and one columns; widening restores its original right column; Progress shows lifetime XP. Portrait at 1080x1350 uses the mobile skill hierarchy and shows the completed project and Unlock control.

Before, transition and settled XP frames come from the same run. The routine XP holder stays at scale 1 and is freed at animation completion. All captures below are unmodified raw production viewport PNGs and were visually inspected. The card art stays inside its frame; project count, rail and source button fit.

An early harness attempt searched for an offscreen virtualized project without scrolling to it; the test now reaches the real entry first. An intermediate next-project selection used the mono-skill blocker helper, which skipped the combo Shack activity; the final code uses authored action order and the combined test passes. Screenshot review also caught an initial Shop fixture without sufficient medals; the corrected fixture uses medal-eligible activities and explicitly checks the visited screen, avoiding a false round-trip pass.

| Capture under `.codex-tmp/desktop-responsive/` | Dimensions |
| --- | --- |
| project-contribution.png | 1920x1080 |
| shop-visited.png | 1920x1080 |
| details-restored.png | 1920x1080 |
| narrow-running-skill.png | 1280x720 |
| lifetime-progress.png | 1920x1080 |
| routine-xp-before.png | 1920x1080 |
| routine-xp-transition.png | 1920x1080 |
| routine-xp-settled.png | 1920x1080 |
| project-portrait.png | 1080x1350 |

## Remaining acceptance

This was a focused native game test, not an itch.io browser, physical Android or long-session performance test. No viewport/stretch/renderer project setting was changed in this pass. Check the overall feel of routine XP, switching menus and resizing while training during the next manual playtest. Physical Samsung rendering acceptance remains required before Android release.
