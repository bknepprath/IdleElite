# Mission Board layout validation, October 7, 2026

The Mission Board now uses separate Missions and Upgrade views. The Missions view contains only unlocked slots and no ScrollContainer. All four level-4 slots fit within the wood panel. The Upgrade view compares current and next-level bonuses, with next-level values in yellow. At maximum level it shows current bonuses only. Tabs use the game's existing font and outlined button style.

Validation:
- Visible production main scene, 1080 x 1920, Dummy audio, isolated test data, save writes and online requests disabled.
- Levels 0 through 4: opening, all unlocked slots, panel bounds, mouse/touch tab selection, purchase visibility, max-level disabled purchase, and outside-tap dismissal passed.
- Cooldown refresh preserves the selected view; mission selection reaches its skill and mounts its activity.
- Final visible log: `.codex-tmp/mission-board-final.log`, `mission-board-ui failures=[]`, no reported engine errors.
- Headless regression: `scripts/test-mission-board.ps1`, exit 0, `mission-board-ok`. It reports the existing shutdown-noise category (12 ObjectDB instances and 6 resources at exit); an additional teardown settling period did not remove that warning. The visible run did not report it.
- All 11 raw PNGs in `.codex-tmp/mission-board-review/` were verified as 1080 x 1920. Final level-4 missions and level-0/1/4 upgrade images were visually inspected.
- `git diff --check` passed for the changed implementation and test files.
- No agent-owned Godot process remained after validation. No rendering configuration, economy, release package, or physical-device acceptance changed.

Repeat UI validation with `scripts/test-mission-board.ps1 -VisibleGame`.
