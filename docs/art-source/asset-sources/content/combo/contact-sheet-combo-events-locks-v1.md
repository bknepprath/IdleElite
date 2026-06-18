# Combo, Event, And Lock Contact Sheets V1

Purpose: pre-production source contact sheets for combo modules, temporary event modules, and lock-part variants. These are not runtime assets and should not be wired into `docs/activity-database.json` until individual tiles are approved and sliced.

Style anchors: `assets/content/fishing/actions/03-cast-bamboo-rod.png`, `assets/content/fight/actions/01-shove-wobbly-hay-bale.png`, `assets/content/build/actions/02-patch-fence-with-confidence.png`, `assets/content/woodcutting/actions/03-trim-overconfident-shrub.png`, `assets/content/ui/shop.png`.

Generated source:
- `contact-sheet-combo-events-locks-master-v1.png`
- `contact-sheet-combo-actions-v1.png`
- `contact-sheet-combo-backgrounds-v1.png`
- `contact-sheet-event-actions-v1.png`
- `contact-sheet-event-backgrounds-v1.png`
- `contact-sheet-lock-parts-v1.png`

Prompt:

```text
Create a clean contact sheet for Idle Elite game asset planning. Use case: stylized-concept. Asset type: pre-production contact sheet, not final runtime sprites. Layout: 5 horizontal rows, 4 square tiles per row, even spacing, no labels, no text, no UI. Row 1 combo action thumbnails: Lift Honey From Beehive, Scope Out A Heist, Fight A Shark, Loot A Pirate Ship. Row 2 combo background plates: orchard beehive branch, rooftop heist planning table, open water danger scene, pirate ship deck. Row 3 temporary event action thumbnails: covered wagon ambush drill, suspicious picnic basket, storm-damaged dock repair, washed-up locked crate. Row 4 temporary event background plates: farm road with wagon tracks, picnic field edge, rainy dock worksite, beach tide line with crate marks. Row 5 lock part variants: light gray padlock body, long-short cane-shaped shackle band closed, shackle popped open, tint mask concept, pulse mask concept. Style anchors: Idle Elite cozy farm idle game asset style, chunky hand-painted 2D game art, rounded toy-like shapes, soft painterly shading, bright earthy colors, clear readable silhouettes for phone scale. Linework lock: thick black outlines, consistent stroke weight, clear black internal separation lines, no thin gray brown colored sketchy or soft-only edges. Constraints: no generated words, no labels, no letters, no numbers, no watermark, no photorealism, no glossy 3D render, no tiny clutter, no dark cinematic blur. Contact sheet should feel like approved concept thumbnails, with each tile isolated and readable.
```

QA notes:
- Rejected for runtime planning. The sheet is too detailed, too illustrative, too character-heavy, and the backgrounds are too narrow/small for the required module background direction.
- Rejected character treatment. Any visible player character must match the existing simple cobalt-blue stick-figure action art language; the detailed human figures in this sheet are not acceptable.
- Rejected lock row. Runtime lock work should continue using the corrected two-piece neutral lock already in `assets/content/ui/`; future lock concepts must preserve the blocky lock body plus a single long/short cane-shaped shackle band.
- Keep this file only as an example of what not to approve. Do not slice it into runtime paths.
