# Corner navigation and padlock number spacing

Replaces the central persistent desktop arrow row. Reuses the mobile button factory and chevron drawing. Full button shapes remain inside the gameplay bounds, including their depth outline. Resting state shows only faint chevrons; hover reveals one complete button. The arrows overlay the lower gameplay corners and do not depend on column scroll position. Removing the reserved row returns its height to the activity viewport.

Timing: 100 ms hover intent, 240 ms Bezier fade with a 12-logical-pixel lift, 650 ms exit grace. No looping or automatic attention animation. Keyboard focus reveals the button. The first touch reveals for 2.5 seconds without triggering navigation. Mouse clicks do not leave keyboard focus holding the button open. Leaving the window clears hover. Carousel movement disables activation without flashing an already open button closed.

Padlock level numbers with XP bars move up 18 logical pixels, retaining the existing font, size and horizontal alignment. Locks without bars retain their previous position.

Validation: `scripts/tests/desktop_corner_navigation.gd` runs the actual main scene through the safe visible wrapper, using muted audio and isolated unsaved test data. It checks rest/reveal states, left/right carousel movement, exit grace, focus release, keyboard reveal, first-touch behavior, touch timeout, bounds and portrait exclusion. The broader discovery test now reveals the corners before clicking them.

Raw captures under `.codex-tmp/desktop-discovery/`: `corner-before.png`, `corner-transition.png`, `corner-open.png`, `corner-right.png`, `corner-settled.png` at 1920x1080; `corner-padlock-portrait.png` at 1080x1920. No image resizing or compositing. Log: `.codex-tmp/desktop-corners.log`.

Result: `CORNER_NAV failures=[]`. Inspected the raw desktop rest/reveal frames and the portrait lock: the number is separated from the progress track, and the revealed button keeps its complete outline. Verified PNG dimensions. No Godot processes remained after the test. `git diff --check` passed.

Arrow correction: repeated alpha blending of separate line segments and cap/join circles caused visible dots at low opacity. Replaced those primitives with one continuous rounded contour per shadow/outline/fill layer in the shared chevron renderer. Re-ran the same production test: `CORNER_NAV failures=[]` in `.codex-tmp/desktop-arrow-joins.log`. Inspected refreshed `corner-before.png`, `corner-open.png` and `corner-padlock-portrait.png`; the dots are gone in the faint corner arrows and the mobile buttons retain their shape.
