# Runtime Path Map V1

Generated contact sheets are source art only. Do not reference them from `docs/activity-database.json`.

## Current Combo Runtime Paths

| Page | Module | Action Art | Background |
| --- | --- | --- | --- |
| Fighting | Duel The Angry Stump | `assets/content/woodcutting/actions/14-negotiate-with-angry-stump.png` | `assets/content/fight/backgrounds/02-rising.png` |
| Thieving | Lift Honey From Beehive | `assets/content/combo/thieving/actions/lift-honey-from-beehive.png` | `assets/content/combo/thieving/backgrounds/lift-honey-from-beehive.png` |
| Build | Frame A Treehouse Platform | `assets/content/build/actions/07-add-roof-to-something-roofless.png` | `assets/content/build/backgrounds/02-rising.png` |
| Woodcutting | Carve The Guild's Trophy Oar | `assets/content/woodcutting/actions/22-chop-a-tree-in-four-timelines.png` | `assets/content/woodcutting/backgrounds/04-late.png` |
| Fishing | Anchor Tiny Boat Dock | `assets/content/fishing/actions/12-trawl-from-tiny-boat.png` | `assets/content/fishing/backgrounds/01-pond-dock.png` |
| Thieving | Scope Out A Heist | `assets/content/combo/thieving/actions/scope-out-a-heist.png` | `assets/content/combo/thieving/backgrounds/scope-out-a-heist.png` |
| Fishing | Fight A Shark | `assets/content/combo/fishing/actions/fight-a-shark.png` | `assets/content/combo/fishing/backgrounds/fight-a-shark.png` |
| Fishing | Loot A Pirate Ship | `assets/content/combo/fishing/actions/loot-a-pirate-ship.png` | `assets/content/combo/fishing/backgrounds/loot-a-pirate-ship.png` |

## Current Event Runtime Paths

| Page | Event | Action Art | Background |
| --- | --- | --- | --- |
| Fighting | Ambush Log Wagon | `assets/content/events/actions/covered-wagon-ambush-drill.png` | `assets/content/fight/backgrounds/03-mid.png` |
| Thieving | Suspicious Picnic Basket | `assets/content/thieving/actions/10-crack-the-breakroom-snack-safe.png` | `assets/content/thieving/backgrounds/02-rising.png` |
| Build | Storm-Damaged Dock | `assets/content/build/actions/10-construct-fishing-pier.png` | `assets/content/build/backgrounds/03-mid.png` |
| Woodcutting | Lightning-Struck Tree | `assets/content/woodcutting/actions/16-split-lightning-struck-cedar.png` | `assets/content/woodcutting/backgrounds/03-mid.png` |
| Fishing | Washed-Up Locked Crate | `assets/content/events/actions/washed-up-locked-crate.png` | `assets/content/fishing/backgrounds/00-tide-pool-shallows.png` |

## Current User-Requested Combo Runtime Paths

| Page | Module | Action Art | Background |
| --- | --- | --- | --- |
| Fishing | Fight Rat King | `assets/content/combo/fishing/actions/fight-rat-king.png` | `assets/content/fishing/backgrounds/sewer-pipe-outlet.png` |
| Fishing | Fight Armored Catfish | `assets/content/combo/fishing/actions/fight-armored-catfish.png` | `assets/content/fishing/backgrounds/05-coral-reef-shallows.png` |

## Approval Rule

When a contact-sheet tile is approved, slice it into the matching runtime folder under `assets/content/combo/` or `assets/content/events/`, let Godot generate `.import` metadata through headless validation, then update `docs/activity-database.json` and run:

```powershell
python scripts\sync-activity-database-js.py
.\scripts\audit-activity-database.ps1
```
