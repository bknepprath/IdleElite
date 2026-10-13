# Fishing opportunity input

Report: Ham's October 11 Discord message described a timing-box tap cancelling a fishing activity. Brian identified Fight A Shark, a fishing/fighting combo activity.

Root cause: Fishing's optimized native-scroll input path bypasses the generic card press router. Standard activity cards on that page reached `_on_action_card_input`, which armed a release-to-toggle action without checking the timing opportunity. Release therefore stopped the running activity instead of granting its speed boost.

Change: the fishing GUI card handler now checks the existing opportunity hit/miss rules on press. Handled timing attempts do not arm the release-to-toggle path. Emulated copies of physical pointer events are ignored by this handler. Stat and medal input retain priority over miss feedback. Native fishing-location controls, queue selection, gameplay balance, saves, and Android rendering settings are unchanged by this fix.

Regression runner: `scripts/test-fishing-opportunity-input.ps1`. It uses the safe Godot wrapper and isolated profiles for Practice Pool and Fight A Shark. It checks real viewport mouse and touch input, successful and missed timing attempts, progress changing between press and release, emulated pointer copies, and ordinary start/stop.

Validation: the pre-fix Practice Pool test reproduced cancellation and missing boosts for mouse and touch. The final headless regression passed for both Practice Pool and Fight A Shark, including emulated pointer events. The existing `fishing_queue_audit.gd` passed. Fight A Shark also passed the muted visible production-scene test; its timing success feedback and increased progress were inspected in the raw viewport captures. This fix is included in the v0.7.0 Windows and Web release candidates. Android device acceptance remains pending.

Real-game captures are raw 1080x1920 viewport PNGs from `res://scenes/main.tscn`, reached through the skill menu with deterministic progression setup. Simulation is paused for precise timing assertions; production controls and their input handling remain active. Preview audio is muted.

- `.codex-tmp/fishing-opportunity/fight-a-shark/before-timing-tap.png`
- `.codex-tmp/fishing-opportunity/fight-a-shark/after-timing-tap.png`

Remaining acceptance: check the exported web build and the physical Android build using a real pointer/finger. The source fix is packaged in the v0.7.0 desktop candidates; nothing has been published.
