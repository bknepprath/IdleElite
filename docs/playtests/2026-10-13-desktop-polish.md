# Desktop polish audit — 2026-10-13

Continued the responsive-layout audit in the existing 0.7.0 prototype worktree. No release package, save-format or gameplay-balance change.

## Findings and corrections

1. Level-98 XP text exceeded the reserved header rail width. Its minimum container width pushed stamina gauges out of compact 4K columns; the earlier level-one test did not cover this. Reproduced in the actual main scene and corrected by fitting the desktop XP font to its reserved width. Full values remain visible. Measurements are cached until the text changes. Portrait headers retain their existing sizing.
2. Generic desktop reward floats animated toward a fixed screen position captured at creation. Moving the carousel could leave an XP popup over another skill. Desktop floats now recompute their anchor-relative location during the existing rise animation, and end if the source control is hidden or freed. Mobile uses its previous path. No reward amount or completion timing changes.

## Verification

`res://scripts/tests/desktop_polish_audit.gd` runs the actual visible `res://scenes/main.tscn` through the safe Godot wrapper. The test profile is isolated, audio uses Dummy, online requests and save writes are disabled.

Baseline: `.codex-tmp/desktop-polish-baseline.log` reproduced clipped Fighting, Thieving and Building gauges at 3840x2160. Initial overlap checks on hidden columns were removed because their container geometry is not settled; final coverage reaches all five skills through the actual corner navigation instead.

Final: `.codex-tmp/desktop-polish.log` reports `DESKTOP_POLISH failures=[]` and `REWARD_ANCHOR horizontal_error=0.0`.

- Level-98 full XP/gauge separation and gauge bounds at 1280x720, 1920x1080 and 3840x2160.
- All five skills reached through real corner buttons; social scores opened/closed through the ribbon at each size. Scores were offline, so this does not verify remote leaderboard retrieval.
- Push-Ups started through its real activity button. A real completion generated the XP popup; a real drag moved Fighting from the left column to the center. The popup tracked its source with zero horizontal error and was freed after its animation.
- Raw before, transition and settled captures from the same 1920x1080 run were inspected. The XP popup remains above Push-Ups through the slide and fades normally.
- All agent-owned test processes exited. No editor or user game was terminated.

## Raw evidence

Files under `.codex-tmp/desktop-responsive/`:

- `audit-level98-3840.png` — 3840x2160, corrected late-game headers.
- `audit-other-skills-3840.png` — 3840x2160, Woodcutting and Fishing headers.
- `reward-drag-before.png`, `reward-drag-transition.png`, `reward-drag-settled.png` — each 1920x1080, one actual completion and carousel gesture.
- Matching header and social captures at 1280 and 1920 widths.

PNG files are unmodified game viewport captures; no cropping, scaling or compositing was applied.

## Remaining acceptance

Real itch.io browser zoom/fullscreen, physical Windows display scaling, physical Android rendering and the sustained performance soak remain separate checks. This pass does not establish release readiness or constant frame rate.
