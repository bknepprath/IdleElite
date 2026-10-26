# Build requirement panel refresh

Purpose: shared overlay for activities purchased once with stored materials, including Duel Fence Post.
Format: transparent wooden plaque, no baked text or icons; generated with the built-in ImageGen tool.
Target: 960 x 240 PNG, fixed canvas; keep aspect ratio. One shared asset for all unbuilt modules.
Style anchor: assets/content/build/actions/02-patch-fence-with-confidence.png.
Shape: two chunky warm wooden boards, heavy black outer contour, simple grain, dark fasteners at ends. Clear central space for the cost row.
Layering: existing activity title and Build button remain; plaque covers the lower card face. Resource icons and outlined cost text are native controls.
Animation: preserve existing build completion fade and movement.
QA: inspect transparent perimeter, readable enlarged resource icon, desktop and portrait real-game captures, exact-once material payment.

Generated master: `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/exec-7acc2371-81b5-4cf6-bc8f-28dc4824e673.png`.
Prompt: `build-requirement-imagegen-prompt.txt`. Built-in ImageGen, transparent output.
Integrated asset: `assets/content/ui/build-required-plaque.png`, 960 x 240. Mechanical crop of transparent master padding followed by proportional downsampling; original generated alpha retained. No drawn substitute artwork or runtime bounds-based scaling.
Original defect: the old wide-plank PNG contained a pale textured perimeter. The cost heading and amount explicitly used zero outline, and the resource icon was 67 px. The replacement uses a black-edged plaque, a single centered Cost/icon/amount row, 176 px icons with linear filtering and 16/18 px text outlines.

Validation: `scripts/tests/build_panel_refresh.gd`, log `.codex-tmp/build-panel-final.log`, `BUILD_PANEL_REFRESH failures=[]`. Actual production scene via muted visible safe wrapper. Raw captures in `.codex-tmp/desktop-responsive/`: `build-panel-desktop-ready.png` (1920 x 1080), `build-panel-portrait-ready.png` (1080 x 1920), `build-panel-transition.png`, `build-panel-built.png` (1920 x 1080). Inspected all four. Actual UI clicks reject insufficient resources, charge exactly three Scrapwood once, grant exactly 60 Building XP, preserve Fighting XP, avoid starting training on the build tap, remove the overlay, then start the built activity without another charge. Generated plaque is 182,485 bytes; no pale pixels detected at its opaque perimeter. No tracked import-file drift remains.
