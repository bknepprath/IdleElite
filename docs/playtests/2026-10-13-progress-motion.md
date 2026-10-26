# Progress-bar motion and padlock prototype — October 13, 2026

## Changes

Stopped activities were skipped between static UI refreshes, which occur every 0.5 seconds. Their canceled progress therefore drained in large jumps despite simulation advancing continuously. The UI now refreshes draining cards every frame until they reach zero. A display-only scale starts the drain at the fill already on screen, preventing a jump upward when the live value was slightly ahead of its smoothed display. The canceled-progress decay rate, stored value and ability to resume it are unchanged.

The high-frequency update condition only recognized the selected skill. On desktop, moving focus to a different column could reduce a running activity, including tired training, to the same 2 Hz refresh. Active desktop training now retains frame updates regardless of focused column. Tired speed and stamina rules remain unchanged.

Level-requirement padlocks now include a small rounded, outlined percentage bar inside their body. The fill uses the required skill's color. It reflects total earned skill XP divided by the XP required for that level: 11/22 XP gives 50% on the level-2 lock. Each combo lock uses its own skill's requirement. The percentage stops at 100%, and the bar follows the existing padlock drag, shake, open and drop transforms. Progress interpolation processes only while its value is changing. Unrelated standalone lock rigs keep their previous layout unless supplied an XP-progress value.

This is a playable prototype for review. It adds no currency, save field, art asset or unlock cost. Project resources and Wisdom remain separate requirements; this bar only measures the lock's level requirement.

## Validation

- `scripts/tests/desktop_progress_motion.gd`: PASS, no script errors. Runs the production main scene visibly through the safety wrapper, muted with the Dummy driver and isolated saves.
- Actual UI input starts Push-Ups and switches to Thieving with progress halfway through. Frame samples verify frequent monotonic drain steps, no upward jumps, and a complete return to zero.
- Tired Thieving continues to animate every frame while Fighting has pointer focus. The measured run reported over 80 distinct drain updates in one second and over 100 tired-progress updates in 0.9 seconds, rather than two updates per second.
- Padlock progress checked at 50%, 100%, and separate Fighting/Thieving combo requirements.
- `scripts/tests/activity_progress_turnover.gd`: PASS (`activity-progress-turnover-ok`), preserving the existing cycle-drain/handoff curve.
- Raw main-viewport captures inspected at 1920x1080 desktop and 1080x1920 portrait. No cropped, resized, composited or helper-scene proof images.
- Automated Godot instances exited after validation. No export or release was made.

## Captures

All paths are relative to this document:

- `../../.codex-tmp/progress-motion/lock-half-desktop.png`
- `../../.codex-tmp/progress-motion/lock-half-portrait.png`
- `../../.codex-tmp/progress-motion/lock-complete-portrait.png`
- `../../.codex-tmp/progress-motion/switch-before.png`
- `../../.codex-tmp/progress-motion/switch-transition.png`
- `../../.codex-tmp/progress-motion/switch-settled.png`
- `../../.codex-tmp/progress-motion/tired-before.png`
- `../../.codex-tmp/progress-motion/tired-transition.png`
- `../../.codex-tmp/progress-motion/tired-settled.png`

Manual follow-up: judge the padlock design in normal play, switch back before a canceled bar empties, and try tired training while moving between columns. Physical-phone and browser validation were not performed in this turn; rendering settings are unchanged.
