# Ad bonus presentation asset contract

## Revised direction after owner feedback

Latest hero request: replace the television/bench illustration with a powered-up blue character, orange stripes and flames, holding chunky extruded versions of the game's exact stamina lightning-bolt and time hourglass glyphs. Generate a new transparent static landscape PNG; no TV, bench or extra text. Use approved blue-character anchors for style and `infochip-symbol-stamina-outlined.png` / `infochip-symbol-time-outlined.png` as symbol-shape references. Orange flames are part of this static UI illustration, not animation body frames. Keep the tan blue-book backdrop and responsive live controls.

Accepted in-game integration: `assets/content/ui/ad-bonus-hero-powered-up.png`, copied unchanged from built-in ImageGen output `C:\Users\bknep\.codex\generated_images\01a161b4-f161-76f1-bd8e-087af0f1c070\exec-aa0974e4-227b-4b01-9552-eda98b4a29e8.png`. The PNG is 1643x957 RGBA. References were the approved market-stall blue character and both actual outlined stat symbols. Its authored responsive draw box is 250–380 design pixels high; no alpha-derived scaling. Alpha was inspected only for edge QA. The visible art remains inside the source canvas. The selected background remains unchanged. Raw production-main-scene verification passed at five phone proportions, including light/dark themes and short-screen scrolling. See `docs/playtests/2026-10-22-ad-bonus-powered-up.md`.

The wood/brass/green frame was rejected as resembling a pool table. Replace it with a new opaque portrait tan backdrop (`ad-bonus-backdrop-v2.png`), using subtle warm gradients, a faint blue wash and a few low-contrast illustrated details at the outer edges. Keep the center quiet and recognizably the game's tan paper color. No physical frame, enclosing outline, rails or corner fittings. Preserve the independent character/television hero and all live controls. The user's explicit request authorizes gradients for this backdrop. Scale the environmental plate with aspect-preserving cover; keep the foreground illustration independently fitted. Retain responsive spacing, readable text and short-screen scrolling.

Final selection: after four additional generated options, Brian selected the bottom-right blue book. Production now uses `assets/content/ui/ad-bonus-backdrop-blue-book.png`, copied unchanged from generated `exec-c40693c6-ffd5-4dc1-a0b1-c36d2a775cca.png`. The former frame and first star/hourglass tan backdrop are not used by this page. A bottom-anchored aspect-preserving source region keeps the book visible on short as well as tall phone proportions. Light-mode type uses dark brown; dark mode dims the backdrop and uses cream/gold type. All four choices remain in `outputs/art/ad-bonus-background-options/`.

The contract below records the rejected first pass for provenance.

Purpose: a full illustrated presentation for the production ad bonus page, with live rewards, button, countdown and developer note remaining Godot controls.

- Frame: opaque portrait PNG, nominal 1080x1920. Chunky warm wood, simple brass corner fittings, dark forest-green inset. Plain stretchable edge middles and quiet center; no text or baked controls. Render as a nine-patch frame anchored to the available page rectangle.
- Hero: transparent landscape PNG, nominal 1024x512. Bright blue game character beside a small retro reward television and an hourglass. One authored draw box above the live offer; preserve aspect ratio.
- Style anchors: approved `assets/content/build/actions/06-build-market-stall.png`, `assets/content/fishing/actions/03-cast-bamboo-rod.png`, and `assets/content/ui/shop-icon.png`.
- Subject reference: `assets/content/ui/rewarded-ad-icon.png` defines the optional-ad television motif, not the style lock.
- Style: thick consistent black outlines, chunky rounded shapes, main/highlight/shadow color areas, no textures, gradients or tiny detail. This follows the project's October 14 three-tone correction.
- Layering: full-page frame, independent hero, then live controls. The frame and hero must never mask controls or bottom navigation. No new animation assets.
- Responsive contract: preserve corner/hero proportions; resize quiet center and rails; use available page bounds with responsive spacing and scrolling only when needed. Do not change project viewport, stretch or renderer settings.

## Generated assets and integration

Built-in ImageGen produced these separate assets using the approved market-stall and bamboo-fishing references. The hero also used the existing rewarded-ad icon as its subject reference. Both prompts specified chunky shapes, thick black outlines, main/highlight/shadow areas, no text, and no baked controls. The frame prompt reserved a quiet forest-green center and plain stretchable rails with corner-only ornament. The hero prompt requested the blue character, wooden bench, retro television with play triangle, hourglass and one gold star, with real alpha.

- `assets/content/ui/ad-bonus-frame-v1.png`: 941x1672, opaque. Source generation `exec-3e107433-a50c-4d9c-9d50-30fb054bbfd9.png` under `C:\Users\bknep\.codex\generated_images\01a161b4-f161-76f1-bd8e-087af0f1c070`.
- `assets/content/ui/ad-bonus-hero-v1.png`: 1774x887 RGBA. Source generation `exec-cac2ba32-e7d1-4cd8-a946-6bc510fa1db8.png` in the same directory. The visible illustration has transparent margins on all sides; the last source row contains only alpha 0–1 noise. No source pixels were edited.

The production frame uses 164px source patches at each edge, preserving ornament and stretching the plain rails and center. Its overall scale follows phone width. The independent hero uses KEEP_ASPECT_CENTERED inside an explicitly authored responsive draw box, 210–320 design pixels high. Alpha bounds were inspected for edge QA only and never determine display scale. All controls are live Godot UI; text and state were not baked into artwork.
