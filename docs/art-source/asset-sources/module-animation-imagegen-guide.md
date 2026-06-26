# Module Animation Imagegen Guide

Purpose: make each Idle Elite module feel more unique through small, readable action animations while keeping the blue player character consistent across every generated frame.

This guide is the source brief for image generation, slicing, review, and future animation implementation. It is intentionally strict because one inconsistent frame is enough to make an animation feel like a different character.

## Current Target

Level 1 Fighting becomes **Push-Ups**.

Runtime compatibility note: keep the existing action ID `shove-wobbly-hay-bale` until a save-data migration is intentionally designed and validated. The visible module name can change first; the ID is a saved/public data key.

## Non-Negotiable Style Lock

Use these references before prompting:

- `docs/art-source/asset-sources/blue-guy-action-art-review/blue-guy-source-of-truth.png`
- `docs/art-source/asset-sources/exercise-sprite-sheet/exercise-sprite-sheet-source-of-truth.png`
- `assets/content/fight/actions/01-shove-wobbly-hay-bale.png`
- `assets/content/build/actions/02-patch-fence-with-confidence.png`
- `assets/content/build/actions/03-hammer-one-suspicious-nail.png`
- `docs/art-source/asset-sources/combo-event-source-assets/style-lock-anchors-v1.md`

The character must remain the same compact cobalt-blue toy-like stick figure:

- Small round head.
- Short simple arms and legs.
- Rounded torso.
- Continuous body-to-leg connection: legs must attach into the body as one connected blue form. Never separate the body and legs into two pieces with a black line, hip crease, butt seam, underside divider, or body-to-leg cutoff.
- Mitten-like hands with no fingers.
- Thick black outline.
- Minimal internal detail.
- No face, eyes, mouth, hair, clothes, muscles, realistic anatomy, fingers, shoes, or tall mascot proportions.

## Animation Asset Contract

Create animation source as a contact sheet first, then slice approved frames into runtime sprites.

- Runtime frame size: 256 x 256 transparent PNG per frame unless a later implementation chooses a different fixed size.
- Runtime format: save the approved animation as a transparent PNG frame sequence for the game. Use GIF/WebP only as review previews unless the runtime explicitly chooses a baked animation format.
- Runtime effects rule: fire, smoke, glow, magic, weather puffs, and other organic effects must ship as generated or hand-authored bitmap frames/layers. Do not create these effects with Godot `_draw()` circles/polygons, CSS-style shapes, procedural blobs, or runtime gradients; those should be source-only blocking tools at most, never final player-visible art. When smoke needs motion, generate it as a separate transparent sprite sheet of small simple no-stroke puffs, then layer and animate their drift/fade/scale in code instead of baking smoke into the flame or drawing one large cloud.
- Source sheet: uniform grid, one pose per cell, same cell size for every frame.
- Background for generation: perfectly flat chroma key, usually `#00ff00`, then remove to alpha before runtime use.
- Subject coverage: character should occupy about 62-72% of cell height at its tallest pose.
- Padding: keep at least 36 px clear space on every side in a 256 px cell. For low horizontal poses like push-ups, keep at least 28 px above/below and 32 px left/right.
- Contact anchors: define the points that are physically planted before generation. Those anchor points must keep the same pixel position inside each cell after slicing; do not let the whole subject drift, float, or be redrawn in a new place every frame.
- Contact patch lock: for planted hands, feet, toes, knees, or tools, the visible contact patch must stay stable, not just a single invisible point. If the chosen anchor pixel is fixed but the foot/hand silhouette changes size, slides, swivels wildly, or appears to crawl around the point, the animation still fails.
- Contact plane: define the "floor" or support plane that planted anchors push against. This plane can be invisible in final art, but it must exist in the pose logic. Hands, toes, knees, tools, or props should press into that shared plane; bodies rotate, bend, compress, or lift relative to it.
- Motion realism: apply real movement mechanics to the simple blue-guy body. For planted-body exercises, hands and toes stay planted on the contact plane while joints rotate and the torso lowers/rises. Do not add realistic anatomy, but do obey realistic pivots, contact points, arcs, contact pressure, and weight.
- Construction guides: if image generation cannot preserve anchors on an invisible plane, use a source-only contact guide. The guide represents the world/floor plane, so it must be a fixed overlay shared by all frames, not a shape that is redrawn or bent by the generated pose. The character must be authored against the guide: hand and toe contact pixels must actually land on the guide/contact dots. A fixed guide behind a floating character is a failed sheet, not an improvement. For planted-contact actions, the guide and its contact dots must never bounce, pulse, resize, crawl, or shift between frames. Use a simple temporary line or tiny anchor dots to define the plane and contact points, then remove those guides before runtime slicing. Do not confuse source construction guides with approved runtime art.
- Slicing rule: never center each frame independently by its alpha bounding box when contact anchors matter. Slice every frame with the same cell-space crop, scale, and offset, or explicitly align the chosen anchor point before export. Per-frame auto-centering makes planted feet and hands float.
- Camera: locked orthographic side view, three-quarter side view, or action-specific overhead three-quarter view; do not rotate between frames.
- Scale: head, torso, hand size, outline thickness, and limb length must match across all frames.
- Loop: first and last frame must be visually compatible so the animation can cycle without a pop.
- Tween support: do not rely on perfect mathematical middle frames. A good animation needs strong key poses with close supporting tween frames around contact, stretch, squash, or direction changes. The support frames should sit near the key pose they are cushioning, not exactly halfway between two poses.
- Timing support: define hold frames and playback timing separately from the art frames. Natural exercise motions often pause at a stable anchor key before moving again; do not play every frame with identical duration if the real action has effort, balance, or reset beats.
- No baked shadows, labels, UI, text, frame borders, scenic background, floor plane, or props unless the module specifically requires them.

## Recommended Workflow

1. Generate a single clean **model/pose sheet** for the action with all frames visible together.
2. For physics-sensitive actions, build a mechanical blocking sheet before final art. The blocking can be simple shapes, but it must prove the anchors, contact plane, pivots, rotation arcs, and timing.
3. Inspect the blocking sheet. If the mechanics are wrong, do not generate final art yet.
4. Generate or redraw the polished sprite sheet using the approved blocking sheet as the pose/mechanics reference and the blue-guy source sheet as the style reference.
5. Inspect the polished sheet against the blue-guy source of truth.
6. Reject the sheet if the character changes size, limb length, outline style, silhouette, contact anchors, floor plane, or pivot mechanics between frames.
7. Identify the real key poses first, then add close tween frames that cushion into or out of those keys.
8. If construction guides were used, remove them only after verifying the generated poses obey the guide.
9. Slice only approved frames. For anchored animations, use one shared crop rectangle and one shared transform for every frame.
10. Remove chroma key with border-connected background removal, not global white/green deletion.
11. Verify transparent corners, opaque subject pixels, consistent bounding boxes, and matching contact points. Check the final sliced PNGs or GIF, not only the source sheet, because a bad slicer can introduce anchor drift.
12. Build a timed preview with realistic frame durations. For push-ups, hold the top frame longer than the transition frames.
13. Wire the animation only after the mechanical blocking, source sheet, sliced frames, contact anchors, and timed preview pass visual QA.

Avoid generating each frame in isolation. Isolated frame prompts almost always drift in proportions, camera angle, line weight, and character identity.

## Approved Export Package

For each approved module animation, keep the whole decision trail in one attempt folder:

- `*-raw-generated.png`: untouched image-generation output.
- `*-01.png` through `*-04.png`: transparent runtime frames, all exported from the same crop/scale/anchor transform.
- `*-sheet.png`: transparent contact sheet of the runtime frames.
- `*-green-sheet.png`: chroma-background review sheet for quick visual inspection.
- `*-preview.gif`: timed human preview. This is for review, not the preferred runtime source.
- `*-floor-sheet.png` and `*-floor-diagnostic.gif`: fixed code-authored contact guide overlays for anchor review only.
- `proof-unique-frame-metrics.txt`: hashes, bounds, and frame-difference proof that frames are unique.
- `qa-notes.txt`: short notes on what passed, what is still watchlisted, and timing used.

Runtime should consume the transparent PNG frames, not the preview GIF. Frame sequences preserve alpha cleanly, let Godot control timing/holds, keep anchor alignment debuggable, and avoid GIF color/palette artifacts around the blue outline.

## Godot Runtime Packaging

For the actual game, package approved action animations as one transparent atlas plus tiny timing metadata:

- Atlas image: one row of fixed cells, for example `1024 x 256` for four `256 x 256` frames.
- Static fallback art: frame 1 as a standalone transparent PNG, used anywhere the animation system is unavailable.
- Metadata on the action definition:
  - `atlas`: runtime atlas path.
  - `frame_count`: number of cells.
  - `cell_width` and `cell_height`: fixed region size.
  - `sequence`: playback order, usually ping-pong such as `[0, 1, 2, 3, 2, 1]`.
  - `durations`: per-sequence-frame seconds, with real holds such as a longer push-up top pause.

Do not ship review GIFs, green sheets, raw generated sheets, or diagnostic overlays as runtime UI art. Keep those in docs/source folders only.

In game UI, animated action art must be state-aware:

- If the module/action is currently running, play the atlas sequence.
- If the module/action is not running, stop animation and show frame 0 frozen.
- Never animate inactive module cards just because they have an animation atlas.
- If one animation cycle represents one action attempt, prefer progress-synced playback instead of a free-running loop. The progress bar and animation should reach their completion pose at the same time.

For Push-Ups specifically, the runtime sequence is a single rep tied to action progress: top plank, lower, bottom, push back up, top plank. XP/completion should land on the pushed-up/top frame, not while the character is still down.

## Source-Locked Escalation Rule

If image generation repeatedly ignores the active source sheet, stop asking for another full-sheet redraw. A prompt-only retry is not a new strategy when the failure is character topology, body proportions, or source-style drift.

Use a source-locked pass instead:

- Crop or trace the closest approved source pose for the action.
- Preserve the source pose's actual head/body/limb proportions, outline weight, highlight language, and body-to-leg topology.
- Create tweens by rigging, warping, or redrawing from that source pose while keeping the same planted contact anchors.
- Export with one shared cell crop and one shared anchor transform.
- Use image generation only as a controlled polish/edit pass after the source-locked pose mechanics already pass.

For Push-Ups, the exercise sprite sheet row-3 push-up poses are the topology source. A generated sheet that creates a tall blue guy, slick 3D toy render, long underside stripe, body-to-leg seam, fat belly/butt mass, or one-leg tail fails even if the pose broadly reads as a push-up.

## Body-To-Leg Connection Rule

For all generated blue-guy action art, the torso/body and legs must read as one continuous character shape. Do not split the lower body into a separate torso piece and separate leg piece with a visible black divider line.

Allowed:

- Outer black outlines around the whole character silhouette.
- A subtle lengthwise separation between two legs when it is needed to show leg overlap.
- Blue shading or highlights that preserve the continuous body-to-leg form.

Rejected:

- A black line under the torso and above the legs.
- A hip crease, butt seam, pelvis seam, glute line, rear contour, or underside divider.
- Any line that makes the body and legs look like two disconnected pieces.
- Any push-up frame where the body reads as a round butt/belly mass with legs attached below it.

## Master Prompt Template

Use this template for every new module animation. Replace bracketed text only.

```text
Use case: stylized-concept
Asset type: Idle Elite mobile game action animation source sheet
Primary request: Create a clean sprite animation contact sheet for [MODULE ACTION].
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background only.
Subject: the same compact cobalt-blue stick-figure player character from the provided references, performing [ACTION DESCRIPTION].
Style/medium: simple 2D cartoony game sprite, thick black outline, flat colors, minimal shading, matching existing Idle Elite action icon style.
Composition/framing: [FRAME COUNT] evenly spaced cells in one horizontal row, one full-body pose per cell, locked camera angle, identical scale, identical outline thickness, identical character proportions, consistent planted contact anchors on a shared contact plane, generous padding in every cell.
Lighting/mood: neutral flat game-art lighting, no cast shadow, no contact shadow.
Color palette: cobalt-blue character with black outline; chroma-key background must be pure #00ff00 and must not appear inside the character.
Constraints: every frame must use the exact same character design, head size, torso size, limb length, hand shape, line weight, and camera angle. Key poses must be supported by nearby tween poses when the motion changes direction; do not place tweens at perfectly even halfway positions unless the action specifically needs mechanical motion. Planted anchors must stay fixed in cell space on the shared contact plane; body parts should rotate or bend around those anchors instead of jumping. Keep the full subject inside each cell with clear padding. No text, no labels, no frame numbers, no watermark, no UI, no scenic background, no visible floor plane unless the module specifically wants a rendered floor.
Avoid: realistic human anatomy, muscles, fingers, faces, facial expressions, clothing, shoes, tall proportions, glossy 3D rendering, painterly texture, changing camera angle, changing scale, cropped limbs, tiny subject, uneven padding, busy details.
```

## Push-Ups V1 Animation Brief

Visible module name: **Push-Ups**  
Skill: Fighting  
Compatibility action ID: `shove-wobbly-hay-bale`  
Target feel: starter training, simple and readable, more playful than aggressive.
Camera: slight bird's-eye three-quarter view, looking down at the blue guy's back. The head sits toward the bottom-left of each frame, and the legs point toward the top-right.
Exercise source update: the exercise sprite sheet is the strongest inspiration/source-of-truth for push-up style, proportions, and pose language, but it should not be treated as a cutout sheet unless explicitly requested. Use it to generate new authored frames that feel like they belong to the sheet: compact side/three-quarter read, slim plank body, two visible short legs/toe pads, no pronounced ass, no belly mass, no fat underside divider, and feet that feel planted.
Source-sheet style gate: do not approve a push-up sheet merely because it is blue and doing a push-up. It must look like it could be pasted into the attached exercise source sheet without standing out: same compact rounded proportions, same soft sticker outline, same highlight language, same small exercise-sprite scale, same feet-left/head-right side-view construction, and no older tall/action-sheet body language.
Body read: preserve the source-of-truth blue guy's simple rounded torso. Do not add an anatomical back, hips, butt, waist crease, shoulder blades, glutes, or realistic body segmentation. Never draw a clear black line that separates a round butt/body mass from the legs.
Neck read: the head must connect through a visible short neck/upper-torso bridge like the bent-over source pose, not float on a prone blob. The viewer should understand where the head, neck, shoulders, and simple torso connect.
Contact anchor rule: toes are the primary fixed anchor at the top-right of every frame, and hands are secondary fixed anchors near the bottom-left. During the push-up, the toes do not float, slide, resize, or jump; the visible toe/foot contact patch stays in the same place on the floor plane while the ankle/leg angle changes. Hands remain planted with only small wrist/arm angle changes.
Hand anchor correction: once the feet are stable, judge the palms with the same strictness. The hand contact patches must not crawl forward, slide backward, or stretch along the floor as the body lowers. The elbows bend above planted palms; the hands do not travel to create the motion.
Foot anchor rule: choose one clear foot/toe contact patch that touches the implied ground and use it as the world anchor for slicing and preview. This anchor must not vertically bounce. If the rest of the sprite shifts, correct the export against the fixed foot anchor before reviewing timing.
Contact plane rule: the push-up happens against an invisible diagonal floor/support plane shared by the hands and toes. The hands and toes press into this plane; the shoulders, neck, head, torso, and hips rotate/lower relative to it. If a visible floor is not desired, do not render a floor, but still pose as if the floor exists.
Construction guide option: for generation and review only, a thin temporary contact-plane guide and tiny anchor dots may be used to force consistent hands/toes. The guide is the fixed floor/reference layer; it must not move, bend, warp, scale, change angle, bounce, pulse, or change dot size from frame to frame. The blue guy must be drawn on top of that physical guide, with palms and toe tips touching the guide in every frame. Do not accept a version where the guide is stable but the character is merely near it, above it, or below it. Do not accept a version where the character is stable but the diagnostic guide/dots bounce under it. Final runtime frames should remove the guide unless the module explicitly wants a visible floor.
Ankle pivot rule: the feet/toes are not just pinned dots. The ankles are the visible pivot. As the body lowers, the feet stay on the floor plane and the straight back/leg body plank rotates around the toe/ankle area. The body angle must rotate relative to the floor plane, but the back and legs should remain straight in relation to each other like proper push-up form.
Push-up form rule: proper push-up form is a straight connected line from upper back through hips into legs. Do not kink the knees, sag the hips, arch the back, or break the legs away from the body. The blue-guy style can stay toy-like, but the silhouette must read as one straight plank supported by bending arms.
Butt/leg attachment rule: do not draw a hard lower butt line, hip crease, pelvis seam, underside divider, or outline that separates the rear/body from the legs. Never draw a clear black dividing line between the round body/butt mass and the legs. Never draw a fat black line below the body and above the legs; this is still a forbidden body-to-leg seam even if it is framed as underside/shadow/overlap. The legs should attach directly into the torso/body shape with a smooth continuous transition. Both legs should be visible in push-up poses; do not solve the seam problem by merging the lower body into a single unileg/tail shape. Use a subtle leg-overlap line only between the two legs, never across the butt/hip/body-to-leg attachment.
Body mass rule: the push-up body should read as one simple plank-like blue-guy torso with two legs, not as a belly bulge plus a butt bulge. Reject pronounced belly, pronounced round butt, pinched waist, or changing torso thickness that makes the body look lumpy.
Torso length rule: the distance from neck/shoulders to hip/leg attachment must stay visually constant across frames. The butt/hip area must not slide up and down the body, stretch, shrink, or crawl along the torso during the animation. The body rotates and lowers as one stable mass; it does not change length.
Leg length rule: both legs must keep the same visual length, thickness, angle relationship, and toe-pad spacing across all frames. Reject any pass where legs extend, contract, telescope, stretch, or become longer in the down frames.
Latest failure note: reject any pass that still reads as an ass/fat body shape, still has visibly moving feet/toe pads, collapses the lower body into a one-leg/unileg read, shows legs extending in length, lets the hands slide across the ground, or keeps a raised mid-back/hip bump that makes the plank feel lumpy. These failures can appear even when the seam is reduced, so review the animated GIF, not only the source sheet.

Frame count: 4-frame prototype for the first test; expand to 6-8 frames for final polish if the motion feels too snappy.
Playback timing: top hold 280-360 ms, near-top tween 70-100 ms, near-bottom tween 70-100 ms, bottom key 80-130 ms, press-up tweens 70-100 ms each, then return to the top hold. The top key should feel like the stable reset/breathing point where the blue guy briefly locks out before the next rep.

Frame sequence:

1. High plank key pose, arms nearly straight, body simple and level.
2. Near-top support tween, about 10% of the way from the high pose toward the low pose, with the same fixed foot anchor.
3. Near-bottom support tween, about 90% of the way from the high pose toward the low pose, with the same fixed foot anchor.
4. Bottom push-up key pose, chest lowered, elbows bent.

The key idea is 2 strong poses plus 2 close tweens: full-up key, 10% tween, 90% tween, full-down key. Avoid a perfect 50% middle frame unless a later action specifically needs a mechanical feel. Runtime playback can ping-pong these frames for a full push-up cycle: `1, 2, 3, 4, 3, 2`.

Recommended preview timing for the 4-frame loop: `1(320ms), 2(85ms), 3(85ms), 4(110ms), 3(80ms), 2(80ms)`. Do not add a long hold at the bottom unless the action is meant to feel exhausted or strained.

Push-Ups prompt:

```text
Use case: stylized-concept
Asset type: Idle Elite mobile game action animation source sheet
Primary request: Create a 4-frame sprite animation contact sheet of the blue player character doing push-ups.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background only.
Subject: the same compact cobalt-blue stick-figure player character from the references, doing a simple push-up loop from high plank to bottom position and back up.
Style/medium: simple 2D cartoony game sprite, thick black outline, flat cobalt-blue character, minimal shading, matching existing Idle Elite action icon style.
Composition/framing: 4 evenly spaced cells in one horizontal row, one full-body pose per cell, locked slight bird's-eye three-quarter camera, identical scale, identical outline thickness, identical character proportions, consistent planted toe and hand anchors on one invisible diagonal contact plane, generous padding in every cell. The blue guy is angled diagonally with head toward the bottom-left and legs toward the top-right, showing the simple rounded torso/back as one clean shape. The character is horizontal but still large and readable at phone-card size.
Lighting/mood: neutral flat game-art lighting, no cast shadow, no contact shadow.
Color palette: cobalt-blue character with black outline; chroma-key background must be pure #00ff00 and must not appear inside the character.
Constraints: keep the exact same head size, torso size, short limb length, mitten hands, line weight, and camera angle in all 4 frames. Frame 1 is the full-up key pose. Frame 2 is only about 10% down from the up pose. Frame 3 is about 90% down toward the low pose. Frame 4 is the full-down key pose. No perfect 50% middle frame. No face, no eyes, no mouth, no fingers, no clothing, no muscles. Show a short visible neck/upper-torso bridge from head into shoulders like the bent-over source pose. No anatomical back, butt, hip crease, waist crease, shoulder blades, glutes, separated rear body sections, or clear black line between the round body/butt mass and legs. Hands and toes must sit on the same floor/contact plane in every frame. The feet stay on that plane and pivot at the ankles/toes. The hands stay planted on that plane. The back/torso/legs remain straight in relation to each other and rotate as one connected plank around the ankle/toe area while the elbows bend. Do not kink the knees, sag the hips, or introduce a hard butt-to-leg separation line. Preserve the diagonal head-bottom-left / legs-top-right staging in every frame. Keep all limbs fully inside each cell with clear padding.
Avoid: realistic athlete, long arms, long legs, detailed anatomy, facial features, floor shadow, frame labels, text, UI, scenic background, changing character size, cropped body, uneven spacing, props.
```

## QA Checklist

Approve an animation sheet only when all checks pass:

- The character reads as the existing blue guy, not a new mascot.
- All frames share the same head size, torso size, limb length, hand shape, outline weight, and camera angle.
- The subject has consistent padding and is never cropped.
- The action reads at phone-card size without zooming.
- The loop has no obvious scale pop between the last and first frame.
- Tween/support frames cushion key poses; they are not just evenly spaced mechanical middles.
- Planted anchors stay fixed across frames. For Push-Ups, toes and hands must not float, slide, scale, or jump; the body rotates and lowers around those anchors.
- The slicing/export process preserves anchors. If the source sheet has stable anchors but the GIF floats, reject the slicer settings and rebuild with a shared crop/transform.
- The contact plane is believable. For Push-Ups, hands and toes should all press against the same invisible diagonal floor/support plane, and the body should lower by elbow bend plus body rotation toward that plane. If the motion feels like the character is floating in space, reject it even if the anchor points are aligned.
- Construction guides are not present in final runtime frames unless intentionally approved as part of the scene. If guides were needed, confirm the cleaned version still preserves the plane.
- Construction guide stability passes. If a guide line is used for review, it must stay perfectly fixed across frames. Prefer drawing the review guide as a code overlay after slicing so it is one immovable world reference. A bent, drifting, or per-frame-redrawn guide means the source generation or diagnostic export is not respecting the physical floor.
- No bouncing guide. For Push-Ups, the red floor line and any red contact dots are a world reference, not animation elements. Reject any sheet or GIF where the guide/dots bounce, jitter, pulse, resize, slide, or appear newly drawn under each frame.
- Construction guide contact passes. A stable guide is not enough. The hands and toe tips must be visibly planted on the guide/contact plane in every frame; if the guide only sits behind the character while the limbs float off-plane, reject it and regenerate from a stricter contact-pose brief.
- Ankle/body rotation is correct. Feet and hands remain on the plane, ankles act as pivots, and the straight back/torso/legs plank rotates relative to the floor as the elbows bend. Reject any sheet where the body appears to slide downward instead of rotating around planted feet.
- Planted foot silhouette is stable. For Push-Ups, do not approve a sheet where the toes are technically aligned but the drawn foot pads crawl, resize, or jump between frames. The foot contact patch must feel like the same object pressing into the same floor spot.
- Foot anchor does not vertically bounce. Pick a foot/toe contact point that touches the ground and verify it stays at the same y-position in every exported frame and GIF.
- Push-up form is correct. Back and legs stay straight in relation to each other. Reject bent knees, sagging hips, arched backs, broken leg attachments, and any hard lower butt/hip line that separates the rear from the legs.
- No body-to-leg seam. Reject any push-up frame with a clear black line dividing the round torso/butt mass from the legs. This has been a repeated failure mode and should override otherwise good contact mechanics.
- No underside divider. Reject any push-up frame with a thick/fat black line below the body and above the legs. That line reads as a body-to-leg cutoff seam and is not allowed.
- Two-leg read is clear. Reject any push-up frame where the lower body becomes a single merged unileg/tail shape. The correct read is two simple blue-guy legs that attach smoothly into the body, with no awkward protruding butt and no body-to-leg cutoff seam.
- Body mass is smooth. Reject pronounced butt bulges, belly bulges, pinched waists, or lumpy torso changes. The blue guy should feel compact and rounded, but the push-up plank must not look like separate belly and butt forms.
- Torso length is stable. Reject any loop where the hip/butt/leg attachment appears to slide up and down the torso, or where the torso stretches/shrinks between frames. Motion comes from elbow bend and body rotation, not a changing body length.
- Leg length is stable. Reject any loop where either leg appears to extend, contract, telescope, stretch, or change thickness/length between frames.
- No fat-body/seam/moving-feet/one-leg combo. Reject immediately if the animation still shows a fat or ass-shaped body mass, a black body-to-leg separation line, toe pads that visibly swim or bounce, a lower body that reads as one leg instead of two, or legs that extend in length.
- Mechanical blocking exists for physics-sensitive actions. If a polished generation repeatedly violates the mechanics, stop prompting and make a simple rig/blocking sheet first; use that blocking sheet as the pose reference for the next art pass.
- Timing feels satisfying. For Push-Ups, the top key frame should pause clearly; transition frames should be quick; the bottom key can compress briefly but should not feel stuck.
- Corners are transparent after background removal.
- No chroma-key pixels remain around antialiased edges.
- No generated text, symbols, labels, numbers, UI, watermark, or accidental face appears.
- Frame filenames preserve order, for example `fight-push-ups-01.png` through `fight-push-ups-04.png`.

## Future Module Brief Mini-Template

Copy this block for each new animated module:

```text
Module:
Skill:
Compatibility action ID:
Visible name:
Frame count:
Loop timing:
Frame durations:
Camera:
Contact point rule:
Contact plane:
Action beats:
References:
Prompt:
QA notes:
Runtime paths:
```
