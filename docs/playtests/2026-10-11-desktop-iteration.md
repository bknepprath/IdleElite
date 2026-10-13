# Desktop UI iteration, October 11, 2026

This is source development and visible production-game review. Brian rejected the earlier v0.7.0 desktop presentation. No exports, ZIPs, or release candidates were created in this iteration. The earlier output README is marked superseded and unapproved.

## Changes

- Replaced the text navigation toolbar with a bottom ribbon using the mobile game's existing icon assets and navigation-button styling/press behavior. Progress, Hub, Skills, Shop, and Settings occupy the center. Pinned and Queue are on the left; optional Chat and High Scores are on the right. Active destinations have a small highlight. Labels are available as hover tooltips.
- Removed the duplicate boxed skill selector rows. The existing skill title now opens its selector, preserving the icon, XP display, and stamina/fish gauge.
- Replaced separate rectangular header backdrops with one continuous, horizontally blended skill-color background that fades into the page. Light and dark themes share the same layout.
- Building details open in a left inspector, with the existing building art and upgrade controls. The mission board uses the same left area. The production hub uses the remaining middle area and optional chat remains on the right. Closing the inspector returns that space to the hub. Smaller windows avoid showing both side panels around a compressed hub.
- Social tabs use plain text controls without the previous button boxes. Chat remains closed by default.
- Fixed docked chat being counted as a full-screen modal in the common input guard, which blocked gameplay and ribbon navigation.
- Moved desktop layout/sibling-column updates outside the focused fishing page's idle-UI optimization. Resizing must continue to work when fishing is idle.
- The shared Android viewport and renderer configuration are unchanged. No progression, rewards, activity content, identity, or backend configuration changes were made.

## Review method

The safe Godot wrapper launched the real `res://scenes/main.tscn` with muted monitoring and isolated fixture data. The test completes onboarding, provides level-eight skills and level-two hub buildings, and disables online requests and save writes. Captured controls remain in their production scene hierarchy. The left inspector reparents the actual production detail panel into the desktop shell; it is not a recreated screenshot layer.

Raw captures are saved in `.codex-tmp/desktop-iteration`. The 1920x1080 screenshots are unmodified viewport captures; the suite also checks the 1280x720 view and a 1000x600 fallback. No image crops, resizing, composites, or generated UI images are used.

The input suite covers activity start/stop in each column, independent scroll, retained scroll across social toggles, activity input beside chat, title dropdown keyboard selection, ribbon navigation beside chat, resize with fishing focused, building selection, switching from a building to the mission inspector, inspector close, and the actual dark-mode update path.

The new visual direction remains subject to design review. Broader desktop UX polish, live browser/online acceptance, and physical Samsung acceptance are not claimed complete by this iteration. The old exported packages do not contain these changes and should not be used to review the new UI.

## Verification result

- Final muted real-game input run: `DESKTOP_LAYOUT failures=[]`, process exited successfully. No script/engine errors in the final preview log.
- Headless stability regression suite: PASS after deferring application-resume work out of focus notifications. An earlier visible run exposed scene-tree mutation during a focus notification; resume now runs deferred.
- Crash-audit contracts and leaderboard-cost safety checks: PASS. Targeted whitespace checks: PASS.
- The UI fixture disables offline rewards and clears its suspended marker while running, so unrelated desktop focus changes cannot stall scripted UI actions. This is test-only behavior; production lifecycle behavior is covered separately by the stability suite. This UI pass does not certify real background/resume behavior.
- Final raw Fighting/Thieving/Building, mission-inspector-with-chat, and dark-mode captures were visually inspected at 1920x1080. All agent-owned Godot processes had exited after validation.
