# Desktop resizing — 2026-10-13

Source: the existing `codex/progression-070` prototype worktree. No export or release was produced.

## Changes

- Native startup prefers 1600x900, scales down to the usable monitor work area and centers the decorated window. Multi-monitor origins are respected. The interactive progression launcher uses the same fitter.
- Column selection reserves at least 440 physical pixels and 900 canvas units per skill. The three-column maximum remains. Intro Fighting stays centered until its neighboring columns fit; the existing onboarding gates remain.
- Column width is capped at 1024 physical pixels and 1550 canvas units. Larger screens gain outer margins instead of unlimited artwork enlargement.
- Compact desktop headers reduce spacing and XP rail width while retaining authored gauge and text sizes. Visual inspection caught and corrected clipped stamina gauges in the initial 4K iteration.
- The drag hint wraps when a social panel leaves a narrow gameplay area. Achievement messages follow the gameplay center after resizing or opening Chat, with space above the first-use drag hint; their existing animation coordinates remain local to the moved parent.
- Android project viewport/stretch/renderer settings were not changed by this work. Existing desktop native-resolution drawing and linear/mipmap filtering remain in use.

## Verification

`scripts/tests/desktop_responsive.gd` launches the actual visible `res://scenes/main.tscn` through `run-godot-safe.ps1`, with Dummy audio, an isolated test profile, save writes disabled and online requests disabled. It starts Push-Ups through the actual activity button, resizes during training, opens/closes Chat through the ribbon, enters/exits native fullscreen and opens Settings through the ribbon.

Final log: `.codex-tmp/desktop-responsive.log`: `DESKTOP_RESPONSIVE failures=[]`.

The visible first-session regression suite also passed: `.codex-tmp/desktop-responsive-opening.log`: `DESKTOP_OPENING failures=[]`. It checks centered Fighting, staged neighbor reveals, actual drag input, resizing, gated ribbon features and the Settings reset flow. Both agent-owned test processes exited.

| Raw viewport | Skill columns, social closed |
| --- | --- |
| 800x600 | 1 |
| 1000x600 | 2 |
| 1280x720 | 2 |
| 1366x768 | 2 |
| 1920x1080 | 3 |
| 2560x1440 | 3 |
| 3440x1440 | 3 |
| 3840x2160 | 3 |

Checks include exact viewport size, complete page bounds, maximum physical column width, all five header gauge bounds, ribbon bounds and preservation of the running activity. Chat was exercised at 800, 1280, 1920 and 3840 widths. Native fullscreen retained training and gauge bounds. The startup fitter passed synthetic work areas including negative monitor origins and small laptop work areas; the actual decorated startup window was inside the detected 2560x1440 monitor work area.

Raw production viewport PNGs are under `.codex-tmp/desktop-responsive/`. Inspected laptop, chat, ultrawide and 4K captures; no post-capture cropping or scaling was applied to these files. The capture viewer may scale its display. The 4K screenshot shows all complete gauges after the fix. The training fixture also exposed an achievement message retaining its old position across a resize and overlapping Chat. The final run checks and captures the corrected position.

## Remaining acceptance

- Real itch.io iframe resizing, browser zoom and browser fullscreen.
- Windows display scaling at 125%, 150% and 200% on physical displays; no system display preferences were changed.
- Physical Android validation remains a separate release requirement. Desktop checks do not clear Android rendering acceptance.
- Bitmap assets still have finite source resolution; this change limits enlargement rather than replacing all artwork.
- These are layout/interaction checks, not a sustained frame-rate or 30-minute performance claim.
