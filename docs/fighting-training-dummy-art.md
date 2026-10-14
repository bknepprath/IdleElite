# Fighting training dummy revision

## Asset contract

- Purpose: recognizable Fighting XP hub upgrade with cumulative equipment progression.
- Format: transparent 1536 × 1024 PNG; 3 × 2 cells of 512 × 512; five states and one empty cell.
- States: construction sign, wooden dummy, padded dummy, helmet and shield, breastplate and sword.
- Style anchors: `assets/content/hub/hub-tree-sheet.png` and `assets/content/hub/hub-decor-sheet.png`.
- Shape language: thick black outlines, large simple shapes, sparse internal detail.
- Layer: static hub facility sprite; no effects or animation.
- Runtime: retain serialized `fighting_display` ID, five-cell selection and authored 310 × 310 draw box.

## Generation

Built-in image generation. Prompt:

> Use case: stylized-concept. Production transparent PNG sprite sheet for a simple 2D farm game hub. Output 1536x1024, EXACT 3 columns by 2 rows of equal 512x512 cells. Five upgrade states in reading order; bottom-right cell completely empty transparent. Input images 1 and 2 are the approved STYLE ANCHORS: match their thick confident BLACK outlines, basic rounded shapes, earthy flat colors, sparse detail and single broad shadow. No texture, fine grain or gloss.
> Subject: one recognizable wooden combat TRAINING DUMMY progressively upgraded. It is an inanimate T-shaped wooden practice target: round wooden head, upright wooden post, horizontal wooden arms, sturdy crossed wooden feet on a small flat ochre oval. Same frontal slight three-quarter angle and same body proportions across levels. No boxing gloves.
> Cell 0 top-left: small wooden construction sign displaying the unmistakable black silhouette of the round-headed T-shaped training dummy.
> Cell 1 top-middle: the plain wooden training dummy, round head with two small black dot eyes, horizontal arms, broad wooden torso, crossed wooden feet.
> Cell 2 top-right: EXACT same dummy and stand, now wearing a single large RED padded rectangular chest protector. Keep exposed round wooden head and arms. No stitching or buckles.
> Cell 3 bottom-left: same red-padded dummy, ADD a simple gray open-face helmet on its round head and a large round gray shield strapped to its left wooden arm. Keep red padding, wood stand, exposed dot eyes.
> Cell 4 bottom-middle: same helmeted dummy, same gray shield, ADD a plain broad gray breastplate over the red padding and a short straight practice sword held upright in its other wooden arm. All earlier equipment remains. Red padding still visible beneath breastplate. Clear cumulative increase in combat equipment; not trophies or disconnected symbols.
> Every sprite occupies within x=50..462,y=60..450 of its own cell, ground baseline y=450; whole object and outlines must fit with clear margins. All dummy heads centered at same height, bodies same size; equipment broad and readable at 230px on screen. Maximum 8-10 large simple shapes. Flat charcoal-black consistent thick strokes like supplied trees. No tiny hardware, ropes, wood grain, straw, elaborate armor, fingers, expressive limbs, gold, banners, extra props, highlights, glow, background, text, numbers, labels or borders. Genuine transparent alpha immediately outside sprite silhouettes.

## Validation

Saved asset: `assets/content/hub/hub-fighting-display-tiers.png`. Display name is now Training Dummy; save ID, bonuses and costs are unchanged.

The generated sheet and all four built levels were visually inspected in the real hub. Raw captures are 1080 × 1920 in `.codex-tmp/ham-revision-captures/hub-tier-1.png` through `hub-tier-4.png`. The focused gameplay and real-game input capture passed, as did the import and exported-texture inventory contracts. No Godot processes remained after validation.
