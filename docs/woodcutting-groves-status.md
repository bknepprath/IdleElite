# Animated woodcutting groves

Implemented locally on October 25, 2026. Existing activity IDs and medal support positions are preserved; new groves are excluded from legacy tier/neighbor indexing.

| Grove | Level | Harvest |
| --- | --- | --- |
| Birch | 8 | Softwood |
| Pine | 20 | Softwood |
| Oak | 38 | Hardwood |
| Maple | 58 | Hardwood |
| Ancient (purple leaves) | 68 | Hardwood |
| Ironwood | 80 | Ironwood |

Birch/Pine and Oak/Maple are visual varieties within material tiers. Purple Ancient is retained by owner request. Heartwood remains a future direction; magic wood is undecided.

The blue character walks between five to eight randomly positioned trees, faces its target, chops on swing contact, and fells the tree. The upper tree rotates at its cut and fades while the short stump remains grounded. Logs and XP are granted exactly once after the fall, with stamina payment checked before rewards. Trees respawn at fresh random positions. Trees and the character share a ground plane with perspective scaling, foot shadows and depth-sorted drawing. Walking detours around other trunks. The Fighting arena floor supplies the textured ground. Shared axe XP, component levels, local arena upgrades, tree types, tree state and paid work persist. Tree arenas do not earn or display medals; old medal records remain in saves for compatibility but grant no mastery bonuses or tier credit. Grove simulation is excluded from generic offline activity rewards.

The axe ring opens Handle (speed), Head (maximum logs), Grip (accuracy), Sharpening (minimum logs) and Gem (XP). Components spend existing woods or Wooden Parts; advanced Head/Sharpening use Ironwood. Sharpening cannot be purchased beyond a useful minimum-yield increase.

## Art contract

Trees and their matching stumps occupy identical 512px atlas cells with the same authored ground anchor and scale. A stump is a short base just above the roots, not a leafless trunk. Preserve the original lower trunk/root pixels and fit the exposed cut surface at that low cut. Rejected tall capped-trunk sheets must never be used as complete stump sprites.

The falling part excludes the roots and rotates around the same cut. Character animation uses one canonical 640px frame and ground anchor (320,600); runtime per-frame alpha-bound scaling is forbidden. Existing walk/chop pixels are translated offline without resizing, with the chop's front sole fixed across all three poses. The 152.5px draw side preserves the original 122/512 pixel scale. Eight walk phases passed contact/high-phase validation. Production delivery removes both colored ankle identifiers and their black ring outlines from all eight frames; alpha silhouettes remain identical to the validated masters. Transient logs remain separate from character sprites.

## Verification

- `scripts/tests/groves_and_range.gd`: passing harvest, upgrades, stamina, persistence, reset, respawn, paid-shot restoration and exact-once reward checks
- `scripts/tests/grove_capture.gd`: passing real main-scene input checks, all six groves, axe purchases, and slingshot landing rewards
- Raw 1080x1920 before/transition/settled frames: `outputs/verification/grove-field-oct25/`
- Desktop playtest: `scripts/play-level-50.ps1`, isolated offline save, every skill level 50 and every material initially 1000

These changes are not published or installed on the phone. Earlier Android preview installation predates the grove work; physical-device acceptance remains outstanding.

October 25 field revision: canonical worker draw side 122px and tree draw side 200px, with authored ground-depth scale `.82 + depth * .28`. Sizes never depend on frame alpha bounds. Spawn coordinates persist in version 2; older three-tree saves retain earned progress and receive five field slots. `scripts/play-level-50.ps1 -Resume` reopens the isolated playtest without reseeding skills or inventory.

## Arena upgrades and rare trees

Each arena has three independent upgrades, shown as independent raised buttons below its fully land-textured oval arena:

- Max trees: two initial slots, up to eight across six upgrades, adding the new slot immediately
- Regrowth: base 20/24/28/32/36/40 seconds by grove, divided by `1 + 0.10 * level`, up to five upgrades
- Rarity: 5% initial chance plus 7 percentage points per level, up to 40%

Prices use that arena's normal wood: `(level + 1)^2` times 40 for capacity, 15 for regrowth, or 25 for rarity. Upgrading rarity affects future spawns, not existing trees. Regrowth affects the live stump timer. Arena upgrades have their own save map and cloud monotonic guards; they do not replace the shared axe components.

New rare rolls create bountiful versions of the same grove tree: triple the normal log yield, with base durability, wood type, XP and axe XP. They use the existing tree/stump art at one explicit 1.12x state scale and a warmer canopy tint. Historical next-tier rare trees retain their source ID and old reward multiplier. Save version 4 preserves bountiful status and retains an old saved fall even when its former slot exceeds the new base capacity.

`mastery_enabled: false` in the source data disables the six groves through the shared mastery eligibility contract. The existing tier exemption remains. Current evidence: `outputs/verification/grove-arena-upgrades-oct25/`. Gameplay tests cover purchase costs/caps, local upgrade scope, actual early regrowth, rare-tree rewards, no medal grants, save migration, saved coordinates, and cloud protection for paid arena upgrades.


## Oval presentation and worker presence, October 25

The full rectangular shell is removed. A 30px extruded oval carries the land texture and trees; upgrade buttons float below it. Current log inventory, XP and stamina share an unboxed top row with the title. The axe badge is reduced from 192px to 148px and uses `Lv`, with an 18px outline and a shallow circular text baseline.

Inactive workers fade out in 0.35s. Activating a grove returns the worker to front-center and fades him in over 0.45s before walking. Worker presence belongs to the shared runtime, so remounting a card does not restart entry. Damaged trees and pending falls remain valid across stop/start and saves. Local source only. Evidence and checks: `playtests/2026-10-25-arena-polish.md`.


Harvest feedback has no numeric +N label. Each awarded unit schedules one log sprite with an independent staggered lifetime, so successive bursts do not overwrite one another. Ironwood uses a newly generated single-log icon at the existing material path; custom log draws preserve source aspect ratio. Compact arena buttons read Capacity / Spawn / Rarity, with each name and value on one row, price below, the actual woodcutting theme green (#6ea937), and 14px text outlines. Current reward proof: `outputs/verification/grove-rewards-oct25/`.


## Shrub depth, inventory and foot grounding

All fifteen shrub clusters have authored ground anchors and sort with trees and the worker by projected floor position. Trees and workers can pass in front of or behind the same shrub. Clip geometry samples the unchanged shrub border artwork. The axe badge has a radial feathered shadow. Header logs show live inventory, using the existing compact inventory formatter. Purchases update it immediately.

Walk and chop use shared 640px canvases with ground anchor (320,600). Original pixels are translated offline without resizing; each chop front sole lands at (416,600), allowing the head and torso to move instead of sliding the feet. Runtime scale stays fixed at 152.5/640, equal to the previous 122/512 scale.

The initial visible test exposed a dynamically inferred material variable that prevented the grove script from compiling and displayed the fallback card. An explicit String annotation fixes it. The corrected actual-main run passes GROVE_DEPTH failures=[], including inventory 321 to 296 after a real upgrade tap, all three chop poses, shrub depth, badge/shop input and inactive state. Raw 1080x1920 proof: outputs/verification/grove-depth-oct25/.


October 25 grove audio: added varied wooden axe impacts and one quiet collection cue per harvest, synchronized to actual contact and reward grants. Muted/offscreen arenas remain silent. Actual-main timing/mix and grove gameplay checks passed. Evidence: playtests/2026-10-25-grove-audio.md.


## Bonus-yield tree indicator, October 25

Trees with a larger per-tree harvest range than the arena's normal tree carry three illustrated gold flecks, reusing the existing progress-star artwork. They twinkle with staggered opacity, remain attached to the canopy during sway and falling, inherit tree fading/occlusion, and disappear with the harvested canopy. Pine has its own authored branch positions; the other five tree types share broad-canopy anchors. Axe upgrades alone do not mark every normal tree. Gameplay, rarity rolls, saved tree flags and rewards are unchanged.

Actual-main verification: GROVE_GOLD failures=[]. All six normal/bountiful pairs and standing/twinkling/falling/harvested states captured at raw 1080x1920 in outputs/verification/grove-gold-oct25/. Local source only. Brian explicitly requested no phone updates until he asks; no Android build or install was performed for this change.


## Capacity and growth balance, October 25

Capacity prices doubled across all six arenas: 40, 160, 360, 640, 1000 and 1440 units of that grove's normal wood. Each purchase still adds one tree, from two base trees to eight maximum.

Spawn now adds 10 percent growth speed per upgrade, previously 25 percent. Actual regrowth is base seconds divided by (1 + 0.10 times level), with the existing five-level cap and prices. Birch now progresses 20, 18.18, 16.67, 15.38, 14.29 and 13.33 seconds. Existing paid upgrade levels are retained and use the new balance when restored.

Source JSON and runtime fallback updated. Database contracts/audit, grove/range gameplay, and real main-scene button purchases passed. Actual-main evidence: outputs/verification/grove-balance-oct25/ (raw 1080x1920 base, first upgrades, and maximum Spawn captures). No phone build or installation; owner hold remains active.


## Shared shrub ground plane, October 25

Replaced the blanket side-shrub foreground pass. All 15 illustrated shrub clusters have ground anchors traced from the original border, and every shrub, tree and worker shares one depth-sorted draw list. Sorting compares projected floor Y; exact ties use deterministic insertion order. Harvest feedback and header controls retain their overlay layers.

The source shrub-border.png is unchanged. Separate clip polygons cover 100 percent of opaque source pixels, with a two-source-pixel overlap to avoid filtering seams. No per-frame scale corrections or gameplay/save changes. The authored geometry is in shrub-layers.gd with source hash/coverage metadata in shrub-layers.json. Authoring helper: .codex-tmp/extract-shrub-depth-geometry.py; the previous helper delegates to it.

Actual-main verification passed GROVE_SHRUB_DEPTH failures=[]. Front and rear tree placements use valid spawn depths on both edges, plus a mixed-depth scene and worker poses on both sides of a shrub anchor. Raw 1080x1920 evidence: outputs/verification/grove-shrub-depth-oct25/. Phone remains unchanged at the owner's request.

## Walk crossover, October 25

The two passing poses now bring a bent swinging leg across the supporting leg in each half-cycle. Six other production cells remain pixel-identical. Generated debug ankle markers are removed from delivery without changing validated alpha silhouettes. The canonical 640px canvas, ground anchor, fixed draw scale, 10fps order and chop sprites remain unchanged.

Debug phase/foot validation, actual-main two-loop checks in both directions, and grove gameplay checks passed. Raw 1080x1920 proof: outputs/verification/grove-walk-crossing-oct25/final/. Method and asset records: playtests/2026-10-25-grove-walk-crossing.md. Local only; no phone update.

## Upgrade button names, October 25

Current button titles are Trees / Rate / Luck, following Brian's requested replacements for Capacity, Spawn and Rarity. Serialized upgrade keys, prices and effects remain unchanged. Raw actual-main proof: outputs/verification/grove-button-luck-oct25/new-base-prices.png. Local only; phone updates remain on hold.

## Axe shop inventory, October 25

The selected axe component shows an Owned count below its cost material. This reads the material in the next upgrade's live cost, including the switch to Ironwood for higher head/sharpening levels. Counts refresh immediately on selection/purchase and on the existing shop refresh while inventory changes. Capped components clear both cost and owned count. Inventory formatting truncates rather than rounding up; 52px text can wrap inside the existing detail column.

Actual-main touch/mouse selection across all five components, purchase deduction, live empty inventory, Ironwood cost switching, max-level cleanup and portrait/desktop layout passed AXE_SHOP failures=[]. Raw proof: outputs/verification/axe-shop-inventory-oct25/. Prices, effects and save data unchanged. Local only; no phone update.

## Axe contact positioning, October 25

Worker approach distance now matches an authored contact point on the fixed 640px chop canvas and the near bark edge of each tree. Shared grove geometry converts that distance through the live arena's oval perspective and actor scale, including bountiful/legacy tree sizes. Edge approaches choose the other side when needed to keep the stance inside the field. The stage supplies transient field dimensions; these are not save data.

The worker remains just in front of the trunk's ground plane so a rounding tie cannot fade the active tree. Already-running chops and falls are re-aligned when resumed or when arena dimensions change. Canonical sprite scale/ground anchor, source artwork, swing cadence, damage and reward rules are unchanged.

Actual-main GROVE_AXE_CONTACT failures=[]: 72 contact measurements across six tree types, both directions, three depths and normal/bountiful sizes, plus 36 raw 1080x1920 windup/contact/follow-through captures from real approaches. Expected blade penetration is approximately two pixels, rather than crossing the trunk. Existing GROVES_RANGE gameplay checks passed. Evidence: outputs/verification/grove-axe-contact-oct25/final/. Local only; phone remains unchanged.

### Gold-leaf harvest levels, October 25

Source bonus fractions and spawn weights now support one, two and three gold leaves for +25%, +75% and +200% logs. The final marker is one solid gold shape with no stroke or stem, drawn from gold-leaves.svg. Existing bountiful saves without a level retain triple yield; new per-tree levels persist in grove save version 5. Fractional harvest bonuses use stochastic rounding to avoid inflated low-yield rewards. Gameplay and actual-main checks passed across all six trees. Evidence: playtests/2026-10-25-grove-gold-leaves.md. Local only; phone unchanged.
