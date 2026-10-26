# Desktop navigation, Fire Pit and unlock performance

Production scene: `res://scenes/main.tscn`, launched through `run-godot-safe.ps1 --visible-game`, muted with the Dummy audio driver. Test: `scripts/tests/desktop_discovery.gd`. Isolated user-data directory; online requests and save writes disabled. No export or release package created.

## Changes

- Removed the desktop five-skill strip; use the original mobile button factory with its full 480-by-142 logical button box. Arrows move the carousel one skill. Actual dragging dismisses the discovery hint.
- Padlocks keep their original centered number. The curved bar lies above the bottom outline and has no percentage text. Its XP interval begins at the previous activity unlock level. XP updates no longer reset the structural lock state or chain layout.
- Fire Pit artwork is centered in its authored draw box. Chains are not clipped to its face. Feeder visibility depends on the fire state, not the focused column. Identical layout requests do not restart the animation.
- Desktop activity list changes update the affected column in place, preserving neighboring animation nodes. Lazy mounts and static card work are spread across frames. Layout-transition callbacks retain their intended stack across asynchronous waits.
- Medal totals use existing stat-cache invalidation. Global-medal eligibility skips entries below the requested tier before resolving action definitions. Completion schedules the ordinary desktop UI refresh instead of running a second update immediately.

## Evidence and limits

- Baseline local 8-second unlock sample: worst frame 295.882 ms, p99 30.155 ms (`.codex-tmp/desktop-discovery-baseline.log`).
- Final 30-second sample: 3,455 frames, p99 16.931 ms, maximum 57.164 ms (`.codex-tmp/desktop-discovery-final.log`). Repeat: maximum 64.001 ms, p99 23.852 ms (`.codex-tmp/desktop-discovery-proof.log`). Machine load and run duration differ; these are diagnostic samples, not a controlled benchmark.
- Tests assert existing carousel/card identities survive unlocking, full-carousel arrow and drag behavior, hint dismissal, Fire Pit art center, unclipped outer chains, ignition through the real button, and feeder stability through twelve column-focus changes.
- Latest combined verification passed with `DISCOVERY failures=[]` (`.codex-tmp/desktop-discovery-verified.log`): 2,830 sampled frames over 30 seconds, p99 28.001 ms and maximum 60.533 ms. It also verifies that a real mastery award invalidates both skill and tier totals, and that old arena medals grant neither counts nor global buffs.
- `unlock_progress_interval.gd` checks interval boundaries, midpoint, clamping and the first level-2 lock. `activity_progress_turnover.gd` checks canceled-bar continuity.
- Both focused headless checks passed after the visible run. No Godot processes remained after validation. `git diff --check` passed.
- Raw desktop captures are 1920x1080 in `.codex-tmp/desktop-discovery/`: `navigation-before.png`, `navigation-transition.png`, `navigation-settled.png`, `firepit-locked.png`, `firepit-before.png`, `firepit-transition.png`, `firepit-settled.png`. `padlock-portrait.png` is 1080x1920. No post-capture resizing or compositing.

Remaining: occasional frame spikes, final 30-minute soak, physical Samsung rendering and real itch.io embed acceptance. The existing auto-unlock path also treats a nonfocused desktop skill as nonvisible; its ceremony behavior needs a dedicated regression pass. Do not describe every desktop unlock animation or long-session freeze as resolved.
