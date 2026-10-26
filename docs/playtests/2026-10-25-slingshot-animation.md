# Slingshot animation, October 25

Local source changes only. No export, installation or publication.

Both Clear Rockslide and Practice Slingshot use eight shared illustrated poses: loading, drawing, bracing, full draw, forward elastic overshoot, backward recoil, settling and reload. Both bands are separately visible. The supporting arm bends, raises, dips and rebounds while the feet remain planted. Stone launch triggers the release pose; flight, stamina accounting, rewards, upgrades and save keys remain unchanged. The later requested slowdown changes Rockslide from a 0.5s to a 1.4s base firing interval, with up to 0.4s recoil, and Practice to a 1.25s draw and 0.4s recoil.

`slingshot_animation.gd` uses a fixed 512 x 512 authored canvas and ground anchor [220,470]. The source sheet is normalized offline using one 0.85 scale across every pose. Measured feet/bounds position the art only; they never determine animation scale. Rockslide uses a 200px canvas (roughly the same visible character height as its previous tightly packed 145px canvas); Practice uses 300px. The recoil duration scales with Rockslide's existing shot interval, with no extra body translation or whole-sprite rotation.

Rockslide's XP, stamina and Sand appear on one top-right baseline. Practice shows its actual level-based possible XP range beside stamina on one top row, leaving the existing medal clear. The estimate uses the same effective base XP, level, distance bounds and rounding as landing rewards.

## Assets and generation

Built-in ImageGen, transparent output. Approved style anchor: `assets/content/fight/actions/06-outmuscle-angry-wheelbarrow.png`. Character/equipment reference: existing `assets/content/fight/rockslide/slingshot-poses.png`. Integrated asset: `assets/content/fight/rockslide/slingshot-cycle.png`. Final generated source and fixed-scale grounding manifest: `output/imagegen/slingshot-oct25/`.

Final edit prompt: Edit this transparent 8frame slingshot animation, same 4columns2rows grid. The user likes the TWO separately visible yellow bands and their forward overshoot and backward recoil in the bottomrow; PRESERVE THAT RECOIL. Now improve the FORWARD ARM (the arm holding wooden Y fork, pointing RIGHT). It is too stock-still and bolt straight throughout. Make the supporting shoulder, elbow and hand move as a coherent animation. First row frame0: supporting elbow softly bent downward, fork held a little LOW. frame1: hand/fork begins raising and elbow extends a little. frame2: hand/fork RAISED about15px above frame0, elbow still softly flexed. frame3 fully drawn: braced maximum aim, hand/fork a bit higher, shoulder raised, slight visible elbow bend. Bottomrow frame4 release: supporting elbow BENDS a little and fork dips about15px from high aim, BOTH rubber ribbons overshoot in front as existing. frame5 followthrough: supporting arm rebounds UP, fork lifted a little, BOTH ribbons bow back left as existing. frame6: elbow bends more as hand/fork sinks for reload. frame7: ready again holding lower, rear hand nearfork as existing. Do not translate the whole character or feet. Only change forward shoulder/elbow/forearm/fork subtly together, adjust band attachment positions to stay tied to both fork tips. Not a rubber hose straight pipe: clear slight elbow bend but smooth chunky silhouette. Preserve blue faceless head, feet, heavyblackoutline, three-tone blue and mittenhands without fingers. EXACT character scale/groundline throughout. No blur streaks impacts stars text lines labels background. Each full figure has transparent margin and doesn't overlap neighbors. Both straps always separately visible.

## Validation

- `rockslide_gameplay.gd`: `ROCKSLIDE_GAMEPLAY failures=[]`
- `groves_and_range.gd`: `GROVES_RANGE failures=[]`
- `slingshot_animation_capture.gd`: `SLINGSHOT_ANIMATION failures=[]`
- All eight poses captured in both actual-main production cards, reached through real UI taps
- Top stats share a baseline, and Rockslide's title and stats do not overlap
- Raw 1080 x 1920 captures inspected for draw, release and recovery: `outputs/verification/slingshot-oct25/`
- Muted real-game checks; no agent-owned headless process left running

Sandbox headless logs include the known Windows root-certificate-store warning. The visible game log has no runtime errors.
