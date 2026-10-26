# Arena polish, October 25

Local source changes only. No release, upload or phone installation.

## Final behavior

- Rockslide base firing interval 1.4s, previously 0.5s; full first wind-up and up to 0.4s illustrated recoil
- Practice Slingshot draw 1.25s, previously 0.65s; recoil 0.4s
- Shared eight-pose sequence retains both bands, forward elastic overshoot, backward recoil and a flexing support arm
- Rockslide has no medal eligibility, earning, control or progress ring; old save records remain preserved
- Integrity remains internal escape state, with no red dot display
- Boulders use the generated damage states without HP or floating damage numbers
- Saturated green upgrade faces with centered name/value and material/price rows; exact purchase accounting retained
- Groves have no enclosing square shell and use a textured oval with a 30px extruded side
- Upgrade buttons float independently below the oval; title and wood/XP/stamina occupy an unboxed top row
- Axe badge 148px, `Lv` label, 18px outline, baseline and glyph rotation along a shallow 145px-radius circular arc
- Worker fades out in 0.35s when inactive; reappears front-center over 0.45s before walking
- Presence is shared runtime state, so card remounting does not restart entry; tree HP, pending falls and harvest accounting remain preserved

## Checks and evidence

Activity database contracts and audit passed. `rockslide_gameplay.gd` passes slower opening cadence, no mastery, exact rewards/costs, upgrades, saves, escapes and offline guards. `groves_and_range.gd` passes entry/inactive fades, paused entry, grove harvests/upgrades, saved pending progress and paid Practice landing restoration.

`arena_polish_capture.gd` reaches all six production groves and Rockslide through the actual main scene. It verifies real ground input, entry center before walking, fade-out, reactivation, compact badge/shop taps, centered button rows, no medal control, and Speed purchase. Raw 1080 x 1920 frames: `outputs/verification/arena-polish-oct25/`, including inactive, fading-in, walking, fading-out, returning, Lv 12, slow draw, release and recoil.

All previews use the Dummy audio driver. Known sandbox headless certificate-store warning is unrelated to game behavior. No Android display configuration changed.


## Grove rewards and button clarification

New base: two trees. Base regrowth by grove: 20, 24, 28, 32, 36 and 40 seconds. Capacity has six upgrades to eight slots. The two-row buttons read Capacity / Spawn / Rarity, with their value on the same first row and the price below. They use the actual woodcutting theme green (#6ea937), 6px edges and 14px text outlines. Rockslide button text also uses 14px outlines.

New rare spawns are bountiful versions of the same tree, with triple log yield and unchanged base durability, wood type, XP and axe XP. Existing higher-tier rare saves remain valid. Version 4 preserves bountiful flags and old pending falls beyond the new lower capacity.

Removed numeric harvest text. Every awarded unit creates one independently timed sprite; bursts remain separate so a later harvest cannot truncate the previous one. `grove_rewards_capture.gd` passed actual chops, exact awarded sprite counts, bountiful Birch, ordinary Ironwood and settled feedback. Raw 1080 x 1920 proof: `outputs/verification/grove-rewards-oct25/`.

Ironwood art: built-in ImageGen, genuine transparency, one chunky charcoal-bark log with a cream round cut end and one growth ring, heavy pure black outline, three-tone materials, no texture/text/glow. Approved style anchor: `assets/content/fight/actions/06-outmuscle-angry-wheelbarrow.png`; old Ironwood was material context only. Integrated at the existing path `assets/content/woodcutting/groves/ironwood.png`. Prior source preserved at `output/imagegen/ironwood-oct25/previous.png`. Custom UI draws now preserve aspect ratio.

Exact Ironwood generation prompt: `output/imagegen/ironwood-oct25/prompt.txt`. Final checks: `GROVES_RANGE failures=[]`, `GROVE_REWARDS failures=[]`, `ARENA_POLISH failures=[]`, database contracts/audit passed. Final source is open in the resumed desktop playtest; existing skill, material and axe progress are preserved.


## Shrub depth, inventory and foot grounding

Descending side shrubs redraw above depth-sorted trees and workers using polygons from the unchanged shrub border. Rear shrubs remain behind actors. The axe badge has a radial feathered shadow. Header logs show live inventory, using the existing compact inventory formatter. Purchases update it immediately.

Walk and chop use shared 640px canvases with ground anchor (320,600). Original pixels are translated offline without resizing; each chop front sole lands at (416,600), allowing the head and torso to move instead of sliding the feet. Runtime scale stays fixed at 152.5/640, equal to the previous 122/512 scale.

The initial visible test exposed a dynamically inferred material variable that prevented the grove script from compiling and displayed the fallback card. An explicit String annotation fixes it. The corrected actual-main run passes GROVE_DEPTH failures=[], including inventory 321 to 296 after a real upgrade tap, all three chop poses, shrub depth, badge/shop input and inactive state. Raw 1080x1920 proof: outputs/verification/grove-depth-oct25/.


## Android preview installation

Current source exported and installed on Samsung SM-S928U (R5CX22KSM1H), October 25 at 05:04 local time. Preview package com.idleelite.game.preview, version 0.7.2/code 44, updated in place; production package and saved progress preserved. Build-android-preview guards passed with viewport stretch and both gl_compatibility renderers unchanged. No leftover headless process or startup script errors. Initial active Fishing screen rendered without visible corruption. Existing Preview save has Woodcutting level 2; grove gameplay is not yet unlocked, so this installation does not constitute full phone acceptance of active grove animations. Raw phone evidence: outputs/verification/phone-grove-oct25/. Build scratch TEMP/TMP: H:/Codex/Scratch/idle-elite/android-preview. No release or publication.
