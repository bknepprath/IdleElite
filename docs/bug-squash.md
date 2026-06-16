# Idle Elite Bug Squash Log
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Use this file for short project-wide bug notes, especially fixes that reveal a useful debugging rule. Bigger incidents can keep a dedicated postmortem and link back here.

## Entry Template

Date:
Area:
Symptom:
Mistake:
Root cause:
Fix:
Validation:
Rule:

## Action Art Shader Material

Date: 2026-06-15

Area: activity card action art.

Symptom: action art cutouts looked harsh and over-saturated in activity cards.

Mistake: the first wrong assumption was that the source art needed a global visual retune, so a shared action-art shader was changed to desaturate/value-shift every action image. That hid the symptom, changed source art presentation globally, and did not address the user's actual suspicion that the image might be doubled or rendered through the wrong path.

Root cause: normal transparent action cutout PNGs were all getting the custom `ActionArtTextureRect` `ShaderMaterial`, even though they did not need texture masking. The target cutouts were not doubled: `build:stack-bricks`, `fight:shove-wobbly-hay-bale`, and `fight:kick-mud-off-boot` each had exactly one visible `TextureRect`, with `modulate = Color.WHITE`.

Fix:

- `ActionArtTextureRect` now defaults to the plain `TextureRect` render path.
- `_action_art_image()` calls `set_mask_material_enabled(_action_art_needs_texture_mask(path))`.
- `_action_art_needs_texture_mask()` only enables the shader for `/backgrounds/` paths, where a full background-style image may still need rounded texture clipping.
- Normal transparent cutout PNGs render with `material = null`.
- The regression guard rejects shared action-art shader color math such as saturation/value/luma shifts.

Validation: live scene-tree probes checked target action PNG node count, visibility, modulate, material, and texture path. `scripts/test-performance-regressions.ps1` passed after the fix.

Rule: when a transparent cutout looks wrong, first verify live node count, modulate, material, and texture path. Do not globally color-correct art as a UI fix. If a shader was added only for clipping, make it opt-in for art that actually needs clipping.

## Fishing Module Corner Crop

Date: 2026-05-27

Area: fishing area module background art.

Symptom: the full-size fishing area module background looked muddled after changing it from a plain `TextureRect` to `RoundedTextureRect`.

Mistake: solving corner cropping by changing the background art sampling path.

Root cause: the rounded shader cropped the corners, but it also changed how the wide fishing scene was sampled.

Fix:

- Keep the fishing module background as a `TextureRect` with `STRETCH_KEEP_ASPECT_COVERED`.
- Add a separate corner-only overlay above the background and below the border/content.
- Color that overlay with `COLOR_PAPER` so only the square corner spill is hidden.

Rule: when art already looks correct, do not solve corner cropping by changing how the image is sampled. Mask or cover only the unwanted corner pixels.

## Swipe Preview, Locked Module Reveal, And Lock Dragging

Date: 2026-05-27

Area: activity module list, skill-page swiping, locked module reveal, and lock dragging.

Root causes:

- Locked module reveal was rebuilding the page/list structure instead of animating a hidden placeholder.
- Swipe completion kept a transparent preview page as a handoff cover while the real page rendered underneath, so the real page showed through gaps and looked like duplicated modules.
- Removing the handoff cover exposed a scroll-restore jump because the new page became visible before `ScrollContainer` restored its scroll.
- Lock drag release outside the viewport cleared page-level state without forwarding release to the active `ActivityLockRig`.

Fix:

- Keep locked modules as hidden/collapsed placeholders and animate height/alpha when eligible.
- Keep the settled preview page above the real page during scroll restore, but give it an opaque `COLOR_PAPER` backing.
- Clear the cover only after the real page restores scroll.
- Track `active_activity_lock_rig` and forward outside release events to it before clearing page-level input lock state.

Rule: if a swipe glitch looks like duplicated modules, inspect layering first. Covers that hide rebuild/scroll-restore work need opaque backing. For drag gestures, forward release to the component that captured press even if the pointer leaves the original viewport.

## Validation Notes

Use the project-safe validation command:

```powershell
.\scripts\check-project.ps1
```

Expected current behavior: this exits 0 but may print Godot RID/resource leak warnings on shutdown.

Per `AGENTS.md`, after every Godot command check for leftover Godot processes. Leave visible editor/game windows alone unless clearly launched by the validation command and clearly headless.
