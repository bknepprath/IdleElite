# Blocked activity stroke audit, October 14, 2026

## Cause and reference

The excessive perimeter was baked into the generated cover textures. In particular, metal covers stored at 418 x 220 are displayed at roughly 1,000 pixels wide in portrait, amplifying a source outline of 11–13 pixels to roughly 27–32 pixels. Increasing the text outline would compound the problem.

The comparison reference is the ordinary activity card's 6-pixel action-art border and its shared title outline setting (`ACTION_CARD_TITLE_OUTLINE_SIZE`, 17). Project titles now use that shared setting instead of an independent 18. Their existing 60-pixel font remains unchanged for portrait readability. Illustrated contours retain small organic variation rather than forcing every contour to an identical pixel count.

## Integrated assets

All nine cover materials were revised with ImageGen: timber, stone, iron, bronze, silver, gold, titanium, platinum and obsidian. This covers 34 damage frames. Existing asset paths, fixed canvases, cover proportions, project requirements and animation code are unchanged.

- `assets/content/ui/project-timber-states.png`: 768 x 690, three fixed 768 x 230 rows.
- `assets/content/ui/project-stone-states.png`: same layout.
- `assets/content/ui/project-damage-{iron,bronze,silver,gold,titanium,platinum,obsidian}-{0,1,2,3}.png`: 418 x 220 each.

The small resource holders, their icon outlines, padlocks and curved progress-bar outlines were compared with normal activities. They were already substantially closer to the reference and were not thickened to match the faulty covers. Original assets from this audit are preserved under `.codex-tmp/stroke-art-before/`.

## ImageGen provenance and prompts

Source directory: `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/`.

| Materials | Generated source |
| --- | --- |
| Timber | `exec-0456c26f-eec9-42b8-b9fc-5aee475ad57f.png` |
| Stone | `exec-48b97d66-5ba0-4aae-963b-eed750b63f00.png` |
| Iron, bronze, silver, first pass | `exec-458303a1-922c-4b03-b560-f0b3ac9abb9d.png` |
| Iron, bronze, silver, outline correction | `exec-feb1f466-b2cc-4f9b-b72d-0ffbde4e34b3.png` |
| Iron, bronze, silver, final transparent cutouts | `exec-568b31b9-c430-489a-9f3e-dec1ee367bae.png` |
| Gold, titanium, platinum | `exec-4cc48558-515e-461c-bb4f-ae92894b29ff.png` |
| Obsidian | `exec-400922fa-abf8-4644-9b9a-f8e146b776e1.png` |

Generation direction: preserve broad material shapes, color identities, quiet title space and damage progression; reduce exaggerated black outer outlines; replace heavy black bottom bands with material-colored shadow bevels; use main color, highlight and shadow; transparent background; no new text, holders or ornaments. Preserve the authored sprite grid, canonical scale and anchor across damage states.

The first iron/bronze/silver pass remained too heavy in the real game. Final correction prompt: preserve all twelve sprites' geometry, grid, colors and damage. Reduce the outer black perimeter by 60%, aiming for 2–3 pixels per 512-pixel cell; replace the removed inside border with adjacent material color while preserving the outer silhouette. Reduce oversized bolt rims similarly and crack widths by 30%. No halos or other changes; same transparent 1536 x 1024 sheet.

The outline correction retained an unwanted translucent smoky backdrop, which was rejected in the real-game check. A final ImageGen edit removed the entire background, glow, haze and external shadows while preserving the twelve plaques, positions, dimensions, colors, cracks and thin outlines. Exterior alpha was checked before reimport.

Integration performs ordinary fixed-grid slicing and resizing only. Timber/stone use scale 768/source width. Six metal columns use fixed scale 418/480; obsidian uses fixed scale 418/736. Alpha bounds are used only to center a frame on its canonical canvas, never to choose scale. No contours or cracks were procedurally redrawn.

## Verification

The first full production-scene audit passed: `FULL_WIDTH_BARRIERS failures=[]` in `.codex-tmp/barrier-stroke-audit.log`. `scripts/tests/barrier_stroke_audit.gd` boots the actual main scene and reaches each blocked activity in its normal hierarchy, at 1920 x 1080 desktop and 1080 x 1920 portrait. It also checks bounded damage debris and cleanup.

The final iron/bronze/silver correction and an unobscured platinum capture are checked by `scripts/tests/barrier_stroke_followup.gd`. Raw screenshots are `.codex-tmp/desktop-responsive/materials-{material}-{owner}.png` and `materials-{material}-portrait.png`. These files are original viewport captures, not cropped, resized or composited. The follow-up moves the pointer away before capture so Fishing's hover help does not obscure the cover.

Headless imports use the safe wrapper. Pre/post status and logs are `.codex-tmp/stroke-followup-{before-import,after-import}.txt` and `.codex-tmp/stroke-followup-import.log`; no tracked import setting needed restoring. This is a targeted artwork audit, not Android device acceptance or a performance release sign-off.

Final follow-up result: `FULL_WIDTH_BARRIERS failures=[]` in `.codex-tmp/barrier-stroke-final.log`. Inspected the final iron/silver portrait and bronze desktop captures after the transparent-cutout correction; the backdrops are absent and covers fit their visible bounds. Platinum's unobscured portrait also passes visual inspection. Imports and test processes exited normally.
