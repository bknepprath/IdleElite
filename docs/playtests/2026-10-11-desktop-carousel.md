# Desktop carousel and motion verification

Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`.

The desktop skill titles are labels again. Horizontal mouse dragging moves the three visible pages together through the fixed five-skill order: Fighting, Thieving, Building, Woodcutting, Fishing. The sequence wraps in both directions. Opening Chat or High Scores reduces the visible count. Each skill retains its vertical scroll position. Desktop position and scroll values are stored in the existing save payload and accept missing or malformed older preferences.

Five production pages remain mounted while rotating. Rotation changes their positions and reuses their contexts; it does not duplicate the simulation or recreate page nodes. The continuous header gradient travels with the pages. Release uses cubic Bezier timing over 0.26 seconds; short drags return to their starting position. Focus loss cancels incomplete drags.

The old mobile swipe cleanup could recenter the desktop frame and reveal individual gradient shelves after pointer cancellation. Desktop guards now keep those operations on the mobile path. Clipped offscreen scroll containers cannot intercept wheel input over a docked panel.

Desktop panels use the shared cubic Bezier entry/exit helper. Docked social and hub panels combine opacity with a small horizontal movement; page changes and modal overlays fade. Leaderboard categories retain their own animated selection menu; skills do not use that menu.

## Validation

- Safe-wrapper muted visible run of `res://scenes/main.tscn` through `scripts/tests/desktop_layout_input.gd`: `DESKTOP_LAYOUT failures=[]` in `.codex-tmp/desktop-motion/carousel-3.log`.
- Tested three/two-column responsive layout, independent wheel scrolling, fixed headers, activity start/stop, chat and scores, hub inspector and mission tabs, page navigation, dark mode, rapid panel requests, save preference round trip, five-step wraparound, reverse drag, short drag, activity-card drag without action change, outside-window release, focus-loss cancellation and page instance reuse.
- Headless stability suite: PASS. It still reports 12 ObjectDB instances / 6 resources at test shutdown; this pass does not establish a leak-free long session.
- Crash-audit and leaderboard cost contracts: PASS.
- Existing headless mobile swipe release test: PASS (`skill-swipe-release-no-snapback-ok`).
- Raw viewport screenshots were inspected at their original dimensions. Carousel before/transition/settled frames are 1920 x 1080, captured in one production run. Chat motion captures are 1280 x 720.
- No import, Android renderer change, export, release candidate, deployment, or live backend write was performed for this iteration.

## Evidence

All images are unmodified raw viewport PNGs under `.codex-tmp/desktop-motion/`:

- `carousel-left-before.png`
- `carousel-left-transition.png`
- `carousel-left-settled.png`
- `carousel-right-before.png`, `carousel-right-transition.png`, `carousel-right-settled.png`
- `chat-open-0.png`, `chat-open-1.png`, `chat-open-2.png`
- `social-close-0.png`, `social-close-1.png`, `social-close-2.png`
- `mission-inspector-chat-1920x1080.png`, `mission-upgrade-1920x1080.png`

## Remaining manual acceptance

Check the drag distance and settling speed with a real mouse/trackpad in the final itch.io embed, including fullscreen, browser tab changes and a release beyond the browser window. Recheck Android rendering on a physical Samsung before any Android release. The current UI test uses local chat/score fixtures and does not verify live multiplayer services or a 30-minute browser session.
