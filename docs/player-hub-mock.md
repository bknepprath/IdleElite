# Player Hub Mock
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Planning reference for the first Player Hub screen. The HTML companion mock is `player-hub-mock.html`.

## Hub Fantasy

The hub starts as a barren, crappy farm lot: dusty ground, patchy grass, scattered weeds, a few trees on the edges, and tilted signs marking future building hotspots. It should feel like a place the player will improve over time, not a finished village.

The first version should show the entire phone screen, including the gray ribbon navigation at the bottom. The Hub ribbon button is gray/locked until progression unlocks it, then becomes the entry point for the farm.

## Hotspots

| Hotspot | Starting Visual | Built Visual | Primary Purpose |
| --- | --- | --- | --- |
| Fish Pond | Brown dirt patch with a leaning fish sign | Small pond with cattails and water sparkle | Spend fish for global stamina regen speed |
| Barn / Lumber Shed | Ragged planks and barn sign | Small red barn or lumber shed | Spend logs for global max stamina |
| Trophy Case | Crate, post, or empty pedestal | Display stand with best stolen trophy | Thieving trophy passive bonus |
| Notice Board | Wobbly board frame | Job board with pinned notes | Temporary boosted task jobs and job achievements |
| Training Ring | Trampled dirt circle | Simple rope posts / target dummy | Future combat or action speed module |

## Fish Pond Upgrade Ladder

| Level | Cost | Permanent Bonus |
| --- | ---: | --- |
| 1 | 5 fish | +1% global stamina regen speed |
| 2 | 250 fish | Additional +2% global stamina regen speed |
| 3 | 1,000 fish | Additional +3% global stamina regen speed |
| 4 | 10,000 fish | Additional +4% global stamina regen speed |

Max total fish pond bonus: +10% global stamina regen speed.

## Interaction Notes

- Tapping an unbuilt hotspot should open a build panel with cost, bonus, and a clear build button.
- Tapping a built hotspot should open an upgrade/details panel.
- Locked future hotspots can still show signs, but should be visually less saturated and explain the unlock requirement.
- Small grass tufts, weeds, rocks, and edge trees should make the space feel handmade without blocking the hotspots.
- The bottom ribbon remains visible, with locked features shown as gray buttons with small padlocks.

## Launch Scope

For the three-day launch push, the shippable version should prioritize:

1. Hub button and full hub screen.
2. Fish Pond with real fish costs and regen bonus.
3. Barn / Lumber Shed as a log sink if there is time.
4. Trophy Case and Notice Board as visible, labeled future/hotspot shells.

