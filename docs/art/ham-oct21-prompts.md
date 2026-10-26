# Ham feedback artwork, October 21, 2026

Generated with the built-in ImageGen tool. Final runtime files are transparent 256x256 RGBA PNGs. These are static activity portraits, with no transient effects or animation frames.

Style anchors: `assets/content/fight/actions/06-outmuscle-angry-wheelbarrow.png` and `assets/content/build/actions/02-patch-fence-with-confidence.png`. `wrap-hands.png` supplied subject context only. The current project instruction to use three color regions per object supersedes older painterly guidance.

Purpose: replace reused recovery pictures with a distinct readable resting action, and replace the shipwright lockbox picture with a closed box and key. No UI text, medal, frame or badge is baked into the images.

## Recovery atlas prompt

```text
Use case: stylized-concept. Asset type: one production sprite atlas for Idle Elite resting activities. Create a transparent PNG sheet, exactly 3072 by 1536 pixels: 6 columns and 3 rows of equal 512x512 cells, row-major reading order, eighteen separate sprites, NO grid lines, NO lettering, NO numbers. Keep each sprite completely inside its own cell with at least 64px empty transparent margin; no crossing cell boundaries. Each cell is an authored canonical square draw box with ground anchor at y=410, character height roughly 330px. This is a static illustrated icon atlas, not an animation. Style anchors: the first reference (blue character moving wheelbarrow) and second reference (blue character repairing fence). Subject reference third image (wrapping hands) only indicates resting-action visual clarity. Match the faceless bright blue round-headed person, rounded chunky farm props, bold consistent black outlines and black internal separation lines. Three color regions per shape: main, highlight, shadow; no gradients, no texture, no realistic detail. Flat transparent backgrounds, no scene panels. Objects need to read at 180px. Do not include combat impacts, flashes, stars, particles or motion streaks. Characters have no eyes, mouth, hair or clothes except gloves, simple shoes or the specified hood. Restful poses.

Cells:
Row1 col1: Catch Breath Between Rounds: blue person seated on low wooden stool, hands on knees, shoulders relaxed, no other object.
Row1 col2: Shake Out the Gloves: blue person standing with two red boxing gloves dangling loosely down at their sides, relaxed stance.
Row1 col3: Ice the Bruises: blue person seated holding a pale blue ice pack against one shoulder.
Row1 col4: Slow Shadow Boxing: blue person relaxed standing with gloved fists held up in a slow practice stance, no target or fight props.
Row1 col5: Count the Coins: blue person seated at small low table neatly stacking three simple gold coin piles.
Row1 col6: Hide in Plain Sight: blue person quietly sitting behind a large leafy potted shrub, head peeking to side.

Row2 col1: Case the Quiet Corner: blue person leaning against a simple brick corner, observing patiently.
Row2 col2: Lay Low Until Morning: blue person resting on a bench under a small hooded cloak, no sky or background.
Row2 col3: Nap Behind the Market Stall: blue person sleeping curled on a burlap sack next to a single wooden market crate.
Row2 col4: Sit on the Toolbox: blue person seated on a broad red metal toolbox with simple handle and latch.
Row2 col5: Sweep the Worksite: blue person calmly sweeping a small pile of wood shavings using a straw broom.
Row2 col6: Inspect the Blueprints Again: blue person seated examining a large unfolded pale blue blueprint with simple dark construction lines, no text.

Row3 col1: Measure Twice Again: blue person holding a tape measure against a short timber plank on a tiny support.
Row3 col2: Lean on the Axe: blue person standing resting both hands on the top of a grounded axe handle, axe head beside feet, relaxed.
Row3 col3: Snack on Trail Mix: blue person seated on a stump, holding a small open brown snack pouch.
Row3 col4: Oil the Axe Handle: blue person seated polishing a wooden axe handle with a white cloth, axe laid across knees.
Row3 col5: Stretch the Splinters Out: blue person doing an overhead arm stretch beside a small cut log.
Row3 col6: Rest Under the Stump: blue person reclining against a broad stump with a small leafy overhang.

Make ALL eighteen cells distinct, exactly these subjects in this order. No text, logos, UI badges, rounded app-icon frames, opaque background, decorative captions, or baked transient effects.
```

Generated source: `C:/Users/bknep/.codex/generated_images/01a161b4-f161-76f1-bd8e-087af0f1c070/exec-55f28205-dcf4-495f-8218-cced4f4a0709.png`.

The tool returned a 1774x887 atlas. It was uniformly resampled to a 1536x768 six-by-three grid, split into 256px cells, and every cell was uniformly resized to 224px and placed at (16,16) on a 256px transparent canvas. Every sprite uses the same authored canvas. No alpha bounds were used to determine scale.

## Shipwright lockbox generation brief

A small closed wooden keepsake box with dark metal straps and a large brass key beside it, shown as a transparent fantasy-game portrait. Rounded chunky shapes, bold black outlines, three color regions per object, no text, no character, no background, no effects. The tool initially rejected another description; the accepted request used this harmless keepsake-box subject.

Generated source: `C:/Users/bknep/.codex/generated_images/01a161b4-f161-76f1-bd8e-087af0f1c070/exec-afd7fee1-0472-49f3-b22b-d6c2183289f8.png`. The full square image was uniformly resized to 256x256.

## Integration and review

Runtime paths and raw game captures are listed in [the feedback report](../playtests/2026-10-21-ham-feedback.md). All nineteen portraits were inspected in the production main scene at 1080x1920. The runtime portrait controls use a fixed authored inset and rounded mask. A deferred size update prevents Godot's cached old minimum size from enlarging the art past its frame.

