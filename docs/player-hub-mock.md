# Player Hub Mock
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Planning reference for the first Player Hub screen. The archived HTML companion mock is `archive/player-hub-mock.html`.

## Hub Fantasy

The hub starts as a barren, crappy farm lot: dusty ground, patchy grass, scattered weeds, a few trees on the edges, and tilted signs marking future building hotspots. It should feel like a place the player will improve over time, not a finished village.

The first version should show the entire phone screen, including the gray ribbon navigation at the bottom. The Hub ribbon button is gray/locked until progression unlocks it, then becomes the entry point for the farm.

## Hotspots

| Hotspot | Starting Visual | Built Visual | Primary Purpose |
| --- | --- | --- | --- |
| Barn | Brown dirt patch with a leaning barn sign | Beat-up barn that can be repaired over time | Spend logs to improve low success rate activities |
| Fish Pond | Brown dirt patch with a leaning fish sign | Small pond with cattails and water sparkle | Spend fish for global stamina regen speed |
| Trophy Platform | Empty wooden platform | Click to inspect the best stolen trophy buff once earned | Thieving trophy passive bonus |
| Mission Sign | Wobbly sign board near the path | Job sign with pinned notes | Temporary boosted task jobs and job achievements |
| Garden | Plain dirt rows with a leaning garden sign | Planted rows, sprouts, and later crops | Spend mixed resources to extend offline progress |

## Fish Pond Upgrade Ladder

| Level | Cost | Permanent Bonus |
| --- | ---: | --- |
| 1 | 5 fish | +1% global stamina regen speed |
| 2 | 250 fish | Additional +2% global stamina regen speed |
| 3 | 1,000 fish | Additional +3% global stamina regen speed |
| 4 | 10,000 fish | Additional +4% global stamina regen speed |

Max total fish pond bonus: +10% global stamina regen speed.

## Module Bonus Ladders

| Module | Level 1 | Level 2 | Level 3 | Level 4 | Max Total |
| --- | --- | --- | --- | --- | --- |
| Barn | 25 logs, close 10% of failure gap | 250 logs, close 22% of failure gap | 1,000 logs, close 38% of failure gap | 10,000 logs, close 58% of failure gap | Low success activities become dramatically more reliable |
| Fish Pond | 5 fish, +1% stamina regen | 250 fish, +2% stamina regen | 1,000 fish, +3% stamina regen | 10,000 fish, +4% stamina regen | +10% stamina regen speed |
| Garden | 25 logs + 10 fish, +1h offline cap | 250 logs + 100 fish, +1h offline cap | 1,000 logs + 500 fish, +1h offline cap | 10,000 logs + 2,500 fish, +1h offline cap | +4h offline progress cap |
| Mission Sign | 1 active mission slot | Missions give +10% task speed | Missions save 20% stamina | 2 active mission slots | Better boosted-task mission board |

## Barn Success Formula

The barn should not add a flat success bonus. Flat bonuses make already-safe activities hit 100% too quickly and do not feel dramatic enough on risky actions.

Use a failure-gap formula:

```text
barn_factor_by_level = [0.00, 0.10, 0.22, 0.38, 0.58]
barn_bonus = (100 - success_before_barn) * barn_factor_by_level[barn_level]
success_after_barn = clamp(success_before_barn + barn_bonus, 5, 100)
```

Examples at max barn:

| Before Barn | Max Barn Bonus | After Barn |
| ---: | ---: | ---: |
| 95% | +2.9% | 97.9% |
| 80% | +11.6% | 91.6% |
| 60% | +23.2% | 83.2% |
| 40% | +34.8% | 74.8% |

This makes the barn satisfying where players feel pain, without deleting failure from easy tasks.

## Module Notes

- Barn is the log sink and should feel like the player is making rough jobs less chaotic.
- Fish Pond is the fish sink and improves the speed at which stamina comes back.
- Garden is the mixed-resource sink and extends the offline progress cap by one hour per level.
- Trophy Platform is not buildable and is never purchased directly; clicking it opens a read-only panel for the best trophy stolen through Thieving modules.
- Mission Sign should mostly unlock behavior rather than raw stats: boosted tasks, stamina-saving missions, and eventually an extra mission slot.

## Interaction Notes

- Tapping an unbuilt hotspot should open a build panel with cost, bonus, and a clear build button.
- Tapping a built hotspot should open an upgrade/details panel.
- Locked future hotspots can still show signs, but should be visually less saturated and explain the unlock requirement.
- Small grass tufts, weeds, rocks, and edge trees should make the space feel handmade without blocking the hotspots.
- The bottom ribbon remains visible, with locked features shown as gray buttons with small padlocks.

## Build And Upgrade Flow

Hub upgrades should feel tactile, but they should not become long construction timers. The intended build time is short: about 15 seconds.

1. Player taps a hotspot.
2. The hotspot does a quick pop animation.
3. A panel opens with current bonus, next upgrade bonus, price, and build/upgrade button.
4. Player confirms if they can afford the cost.
5. The facility enters a building state for about 15 seconds.
6. A progress bar appears near the facility or in the panel.
7. A smoke overlay puffs over the facility while the bar fills.
8. When finished, the new facility tier sprite pops in with a satisfying scale bounce.
9. The panel updates to show the new current bonus and next upgrade price.

Animation targets:

| Moment | Animation |
| --- | --- |
| Hotspot press | Scale to 0.94, then bounce back to 1.04, then settle at 1.00 |
| Facility first appears | Start at 0.82 scale and 0 alpha, pop to 1.08 scale, settle at 1.00 |
| Upgrade completes | Smoke clears, new tier pops in, small reward float shows the bonus delta |
| Unaffordable tap | Tiny shake and red price pulse |

The build progress bar should be fast and visible. It can sit in the detail panel for implementation simplicity, with an optional small world-space bar above the facility later.

Panel contents:

| Field | Example |
| --- | --- |
| Facility name | Fish Pond Lv 1 |
| Current bonus | Current: +1% stamina regen speed |
| Next bonus | Next: +2% more stamina regen speed |
| Cost | Cost: 250 fish |
| Button | Upgrade |
| Maxed state | Maxed out |

## Asset Contract

The hub should be a modular Godot scene, not one baked background image.

```text
Godot-generated grass/dirt base
+ transparent path overlay
+ transparent facility sprites
+ transparent decoration sprites
+ Godot labels, hit zones, build panels, and ribbon buttons
```

Canvas assumptions:

| Item | Target |
| --- | --- |
| Godot base canvas | 2160 x 3840 |
| Bottom ribbon height | 420 |
| Hub playable art area | About 2160 x 3420 before safe-area adjustments |
| Facility source size | 512 x 512 transparent PNG per state |
| Facility in-game footprint | About 420-640 px wide depending on building |
| Decoration source size | 256 x 256 transparent PNG sheet cells |
| Path art | Procedural Godot-drawn oval stones |

Recommended asset files:

| Asset | Format | Why |
| --- | --- | --- |
| `hub-decor-sheet.png` | 4 x 4 transparent spritesheet, 256 px cells | Grass tufts, rocks, weeds, small flowers, broken plank, little stump, reeds |
| `hub-tree-sheet.png` | 2 x 3 transparent spritesheet, 384 px cells | Three tree silhouettes, each with small/large variants |
| `hub-barn-tiers.png` | 1 x 5 transparent spritesheet, 512 px cells | Locked/buildable/Lv1/Lv2/max barn states |
| `hub-fish-pond-tiers.png` | 1 x 5 transparent spritesheet, 512 px cells | Dirt patch through max pond states |
| `hub-garden-tiers.png` | 1 x 5 transparent spritesheet, 512 px cells | Empty rows through fuller crop states |
| `hub-trophy-platform.png` | Single transparent PNG | Empty wooden platform for the best stolen trophy |
| `hub-mission-sign-tiers.png` | 1 x 5 transparent spritesheet, 512 px cells | Wobbly sign through busy mission sign states |
| `hub-nav-barn.png` | 430 x 430 transparent PNG | Bottom gray ribbon hub icon, matching current skill icons |
| `hub-build-smoke-sheet.png` | 4 x 4 transparent spritesheet, 256 px cells | Soft smoke puffs for build/upgrade animation |

Generation guidance:

- Draw paths procedurally in Godot so they can branch toward moved facilities.
- Generate grass tufts, rocks, weeds, and flowers as a decor sheet so they can be scattered procedurally.
- Generate trees as a separate sheet because they need larger silhouettes and edge placement.
- Generate facility tiers as consistent same-footprint rows so upgrades can swap sprites without moving hitboxes.
- Generate smoke as a transparent overlay sheet, not baked into any facility.
- Do not generate text on signs. Use icons or blank boards; Godot should own labels.
- Keep all transparent sprites in the same slight top-down/front three-quarter angle.

## Launch Scope

For the three-day launch push, the shippable version should prioritize:

1. Hub button and full hub screen.
2. Fish Pond with real fish costs and regen bonus.
3. Barn, Mission Sign, and Garden as visible hotspot shells, with the Trophy Platform as a passive display spot.
