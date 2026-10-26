# Illustrated ad bonus presentation

This framed version was rejected by the owner as resembling a pool table. It is superseded by the selected tan blue-book backdrop. Current evidence: [2026-10-22-ad-bonus-blue-book.md](2026-10-22-ad-bonus-blue-book.md).

Added an edge-to-edge wood-and-brass frame with a dark green center, a separate blue-character/television/hourglass illustration, and cream/gold live typography. The frame ends above the real bottom navigation. The Shop page alone now uses the full available content rectangle. Other page offsets and Android viewport/stretch/renderer settings are unchanged.

The frame is a nine-patch with protected corners; the independent illustration preserves its aspect ratio. Available page height controls hero height and spacing. A flexible gap holds the developer section near the bottom on tall phones. On short proportions, content scrolls inside the stationary frame; text remains at least 52px when displayed at a physical 1080px phone width. The primary button stays visible in every tested proportion, and touch swipes reach the complete developer/rating section.

## Real-game verification

`scripts/tests/ad_bonus_page_capture.gd` visibly loads `res://scenes/main.tscn`, reaches the screen through its actual bottom navigation, and checks the production controls. It passed empty, active, two-hour, full, expiry, duplicate reward callback, button touch/depression/release and dark-mode assertions. It then resized the visible game window to exercise these native viewport proportions:

| Raw viewport | Proportion | Result |
| --- | --- | --- |
| 1080x1920 | 16:9 portrait | Complete presentation fits |
| 1080x2160 | 18:9 portrait | Complete presentation fits |
| 1080x2340 | 19.5:9 portrait | Complete presentation fits |
| 1200x1920 | 16:10 portrait | Developer section reachable by touch scrolling |
| 1440x1920 | 4:3 portrait | Developer section reachable by touch scrolling |

For the extra aspect checks, the OS window is smaller than the native viewport to keep the entire visible game on the monitor. Godot's existing viewport stretch renders the raw PNG at the dimensions above. No source screenshot was cropped, resized, composited or upscaled afterward. The wider native viewports represent shorter phone proportions under the existing expand policy; font sizing compensates for their eventual physical display width.

Final result: `ad-bonus-page failures=[]`. Frame/page bounds, hero containment, primary button visibility, text bounds, readability and status/timer separation checks passed. Inspected the real page states, button animation frames, tall views and short-view footer captures. Fourteen raw PNGs and their dimensions/hashes are recorded in `outputs/verification/ad-bonus-presentation/capture-manifest.json`.

The fourteen-screen audit and UI boundary, activity UI boundary, generated-file hygiene, test-harness, native-1080 migration and crash-audit contracts passed. The headless asset import recorded before/after Git status and preserved tracked import metadata. No host Godot process remained. Preview audio used Dummy, saves were isolated and ordinary save writes/online requests were disabled. No live ad was watched. The phone preview has not been rebuilt for this presentation.

## Evidence

- [Main presentation](../../outputs/verification/ad-bonus-presentation/two-hours.png)
- [Six-hour maximum](../../outputs/verification/ad-bonus-presentation/full.png)
- [Tall phone](../../outputs/verification/ad-bonus-presentation/phone-1080x2340.png)
- [Short phone](../../outputs/verification/ad-bonus-presentation/phone-1440x1920.png)
- [Short phone after touch scrolling](../../outputs/verification/ad-bonus-presentation/phone-1440x1920-footer.png)
- [Dark mode](../../outputs/verification/ad-bonus-presentation/dark.png)
- [Before press](../../outputs/verification/ad-bonus-presentation/empty.png)
- [Pressed](../../outputs/verification/ad-bonus-presentation/button-pressed.png)
- [Release transition](../../outputs/verification/ad-bonus-presentation/button-release.png)
- [Settled](../../outputs/verification/ad-bonus-presentation/button-settled.png)

Asset contract and provenance: [ad-bonus-presentation-2026-10-22.md](../art/ad-bonus-presentation-2026-10-22.md).
