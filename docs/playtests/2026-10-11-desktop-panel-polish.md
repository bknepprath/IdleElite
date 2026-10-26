# Desktop panel polish, October 11, 2026

Source development only. No exports, packages, release candidates, or publishing.

## Changes

- Desktop leaderboard uses a flowing list inside the shared side panel. Removed the bright blue frame from this layout, simplified category selection and row typography, and kept the existing score/category logic.
- Left inspector and right social panel use matching paper surfaces with rounded corners, subtle feathered shadows, and consistent inset spacing. Dark mode refreshes an already-open social panel.
- Ribbon selection uses a muted raised highlight without the cream bottom ridge. Keyboard focus retains a separate visible outline.
- Replaced the detached mission close X with a Back to hub control.
- Mission controls now flow inside the scrollable desktop inspector, using the existing missions, cooldowns, upgrade comparisons, and callbacks. The desktop panel no longer scales the fixed mobile wooden-board layout.
- Chat uses the panel palette for its header, messages, composer, and profile/send controls. Removed its redundant desktop back button and heavy outlined message names. Closing or switching away from desktop restores the mobile overlay background and rebuilds the appropriate shell when reopened.
- Shared Android viewport and renderer settings are unchanged.

## Verification

The muted visible test runs the production main scene through run-godot-safe.ps1 with isolated user data and online requests/save writes disabled. It reaches the controls through production navigation and captures unmodified viewport PNGs at 1280x720 and 1920x1080; it also checks the 1000x600 fallback. Chat messages and populated leaderboard rows are explicit local test fixtures, not live online data. A test-only leaderboard state supplies cached rows while networking remains disabled. No substitute UI is rendered.

The interaction suite checks activity input, scrolling, social toggles, navigation, resizing, inspector close, mission/upgrade tabs, keyboard skill selection, and an open panel following a theme change. Its lifecycle suspension override remains test-only, as documented in the prior desktop iteration report.

Headless parse/boot, crash-audit contracts, leaderboard cost-safety checks, and targeted whitespace checks passed. Live backend behavior and physical-phone acceptance are outside this visual pass.

Evidence: .codex-tmp/desktop-panels. The final run log is verified-preview.log.

Final visible run: DESKTOP_LAYOUT failures=[], exit code 0, no script/engine errors. Raw populated leaderboard, mission list, mission upgrade, building inspector, and chat captures were inspected in light/dark themes at 1920x1080. The wrapper's final process check found no remaining Godot processes.
