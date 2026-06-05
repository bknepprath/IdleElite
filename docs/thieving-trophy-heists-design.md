# Thieving Trophy Heists Design

Design proposal for four special Thieving modules that award permanent hub trophies. These should feel like tiny capers rather than full separate minigames: quick to understand, risky, replayable on failure, and memorable when won.

## Core Format

Each trophy heist unlocks at a Thieving level milestone and appears as a special horizontal module in the Thieving activity screen. These modules are sprinkled through the regular Thieving ladder, but they are sequential trophy gates: the next heist only appears after the previous trophy has been stolen and the player has reached the required Thieving level.

Flow:

1. Player unlocks the heist by reaching the required Thieving level.
2. Player taps `Steal`.
3. The module plays a short staged sequence: casing, obstacle, grab, escape.
4. The attempt resolves as success or failure.
5. On success, the trophy is permanently stolen and appears in the player hub Trophy Case.
6. On failure, jail bars drop down over the module and a cooldown timer appears on top.

The interaction should be closer to a dramatic success roll than a skill test. The fun is in anticipation, reveal, escalating absurdity, and seeing the trophy physically move into the hub collection.

## Shared Rules

| Field | Recommendation |
| --- | --- |
| Unlock cadence | Thieving levels 8, 20, 32, 65 |
| Attempt cost | Stamina, scaling with level |
| Failure result | No trophy, partial XP, cooldown |
| Success result | Trophy, large XP, hub Trophy Case tier unlock |
| Cooldown | 1 min, 15 min, 1 h, 8 h |
| Success odds | Start fair, become risky, improved by Barn/Trophy bonuses if desired |
| Repeat after success | No trophy repeat; card becomes a completed exhibit with flavor text |

Target table:

| Tier | Required Thieving Level | Visibility Requirement | Cooldown On Failure | Base Success |
| --- | ---: | --- | ---: | ---: |
| 1 | 8 | Always visible once level 8 is reached | 1 min | 88% |
| 2 | 20 | Trophy 1 stolen and level 20 reached | 15 min | 68% |
| 3 | 32 | Trophy 2 stolen and level 32 reached | 1 h | 48% |
| 4 | 65 | Trophy 3 stolen and level 65 reached | 8 h | 32% |

The first module should feel forgiving enough to teach the system. The later modules should feel like real gambles because failure blocks the special module rather than just consuming stamina.

## Module Presentation

The special heist module should use the same horizontal asset language as the existing activity modules, with a large central trophy focus layered over a wide background strip. It should contain:

- Background art from `res://assets/content/thieving/heists/thieving-trophy-heist-backgrounds.png`.
- Center trophy art from `res://assets/content/thieving/trophies/thieving-trophy-sheet.png`.
- A large `Steal` button below the trophy.
- Small stats row for success chance, stamina cost, and cooldown risk.
- A jail-bars cooldown overlay that drops down over the whole module after failure.
- A timer label above the bars, for example `Jailed: 00:58`.

The player should click the explicit `Steal` button, not the trophy itself. The trophy art can still do a small hover/bob/pulse so the module feels interactive.

Jail-bar behavior:

1. Failed roll resolves.
2. Vertical bars animate down from the top edge of the module.
3. The module darkens behind the bars.
4. The `Steal` button is disabled or hidden.
5. Timer appears on top of the bars.
6. When cooldown ends, bars slide up or fade out and the button returns.

The bars can be rendered in Godot using repeated dark rounded rectangles, so no separate bar image is required unless a more illustrated overlay is desired later.

## Trophy 1: The Complimentary Spoon

| Field | Value |
| --- | --- |
| Unlock | Thieving Lv 8 |
| Heist name | Case The Cafe Display |
| Trophy | The Complimentary Spoon |
| Tone | Comedically minor, almost embarrassingly easy |
| Location fantasy | A museum cafe counter with a tiny sign that says the spoon is technically part of an exhibit |
| Obstacle | A sleepy cashier, a donation jar, and the player's own guilt |
| Cooldown | 1 minute |
| Hub display | A bent little spoon on a velvet cushion that is much too fancy for it |

Sequence beats:

1. Case: player studies the spoon from three inches away.
2. Obstacle: cashier looks up.
3. Grab: player pockets the spoon with absurd seriousness.
4. Escape: player speed-walks past a sign reading `Exit Through Gift Shop`.

Failure copy:

> You made eye contact with the spoon and lost your nerve.

Success copy:

> Acquired: The Complimentary Spoon. History will be confused.

## Trophy 2: The Crown Jewel Replica Replica

| Field | Value |
| --- | --- |
| Unlock | Thieving Lv 20, after The Complimentary Spoon is stolen |
| Heist name | Lift The Replica's Replica |
| Trophy | The Crown Jewel Replica Replica |
| Tone | British Museum parody: dusty, official, faintly ridiculous, and fake twice |
| Location fantasy | A marble museum wing where a gift-shop replica of a royal jewel has its own replica on display |
| Obstacle | Laser tripline, school trip crowd, overly sincere authenticity plaque |
| Cooldown | 15 minutes |
| Hub display | A glittery fake jewel on a velvet stand, with a tiny plaque admitting almost nothing |

Sequence beats:

1. Case: player spots the replica replica under museum glass.
2. Obstacle: a tour guide explains that replicas are historically important too.
3. Grab: player replaces it with a replica replica replica.
4. Escape: player hides behind a sarcophagus-shaped donation box.

Failure copy:

> The replacement looked too authentic. This damaged the plan.

Success copy:

> Acquired: The Crown Jewel Replica Replica. Nobody knows who owns it.

## Trophy 3: The Idol Of Slightly Bad Decisions

| Field | Value |
| --- | --- |
| Unlock | Thieving Lv 32, after The Crown Jewel Replica Replica is stolen |
| Heist name | Dodge The Temple Refund Policy |
| Trophy | The Idol Of Slightly Bad Decisions |
| Tone | Indiana Jones energy, but Idle Elite silly |
| Location fantasy | A jungle temple exhibit that is somehow inside the museum basement |
| Obstacle | Pressure plate, rolling foam boulder, dramatic hat retrieval |
| Cooldown | 1 hour |
| Hub display | Gold idol on a cracked stone plinth, with tiny motion lines or sparkle pips |

Sequence beats:

1. Case: player weighs a bag of sand with terrible confidence.
2. Obstacle: pressure plate sinks anyway.
3. Grab: idol goes into the backpack.
4. Escape: a suspiciously soft boulder chases the player through velvet ropes.

Failure copy:

> The sandbag was labelled `low sodium` and weighed nothing.

Success copy:

> Acquired: The Idol Of Slightly Bad Decisions. It hums when ignored.

## Trophy 4: The Crown Of Borrowed Empire

| Field | Value |
| --- | --- |
| Unlock | Thieving Lv 65, after The Idol Of Slightly Bad Decisions is stolen |
| Heist name | Empty The Imperial Exhibit |
| Trophy | The Crown Of Borrowed Empire |
| Tone | Finale heist: museum vault, ancient curse, absurd prestige |
| Location fantasy | A locked imperial exhibit behind glass, guards, velvet ropes, and a smug audio guide |
| Obstacle | Rotating lasers, fake curator disguise, curse countdown |
| Cooldown | 8 hours |
| Hub display | Crown under glass in the Trophy Case, glowing enough to make the farm look briefly important |

Sequence beats:

1. Case: player listens to the audio guide explain how impossible the theft would be.
2. Obstacle: lasers rotate in an annoyingly polite pattern.
3. Grab: player swaps the crown with a folded paper hat.
4. Escape: the ancient curse files a complaint with museum HR.

Failure copy:

> The paper hat was too majestic and raised suspicion.

Success copy:

> Acquired: The Crown Of Borrowed Empire. The hub now has diplomatic tension.

## Hub Trophy Case Mapping

The existing hub Trophy Case has four upgrade tiers. These trophies can become the source of that tier instead of being purchased with logs.

| Trophy Case Tier | Trophy Displayed | Passive Bonus |
| --- | --- | ---: |
| 0 | Empty crate or pedestal | None |
| 1 | The Complimentary Spoon | +1% success chance |
| 2 | The Crown Jewel Replica Replica | +2% success chance |
| 3 | The Idol Of Slightly Bad Decisions | +3% success chance |
| 4 | The Crown Of Borrowed Empire | +5% success chance |

If the player steals trophies out of order later, the hub should display the best stolen trophy by tier. Earlier trophies can still be shown in a compact collection drawer or completion list in the Trophy Case detail panel.

## UI Treatment

Each special module should look distinct from regular Thieving actions:

- Wider card or gold-corner badge labelled `Trophy Heist`.
- Trophy silhouette shown before success.
- Cooldown timer replacing the attempt button after failure.
- Four-step progress strip during the reveal: `Case`, `Bypass`, `Grab`, `Escape`.
- Big success pop that shows the trophy art flying toward a small hub icon.
- Completed state: trophy art, acquisition date if available, and flavor text.
- Hidden future state: do not show the next trophy heist until the previous trophy is stolen and the level requirement is met.

The module can reuse normal Thieving art/background structure, but the heist card should have a more theatrical reveal and a permanent-state flag.

## Asset Contract

Generated project assets:

| Asset | Path | Format | Use |
| --- | --- | --- | --- |
| Heist backgrounds | `res://assets/content/thieving/heists/thieving-trophy-heist-backgrounds.png` | 4 x 1 horizontal spritesheet, 3072 x 344, 768 x 344 cells | Activity-style horizontal backgrounds, one cell per trophy heist |
| Trophy source | `res://assets/content/thieving/trophies/thieving-trophy-sheet-source-chromakey.png` | Chroma-key source, 1983 x 793 | Simplified trophy source retained for regeneration/editing reference |
| Trophy sheet | `res://assets/content/thieving/trophies/thieving-trophy-sheet.png` | 4 x 1 transparent PNG spritesheet, 1024 x 256, 256 x 256 cells | Simplified trophy cutouts for heist modules, reward pop, and tiny hub Trophy Case display |

Cell indexing:

| Index | Heist | Trophy |
| ---: | --- | --- |
| 0 | Case The Cafe Display | The Complimentary Spoon |
| 1 | Lift The Replica's Replica | The Crown Jewel Replica Replica |
| 2 | Dodge The Temple Refund Policy | The Idol Of Slightly Bad Decisions |
| 3 | Empty The Imperial Exhibit | The Crown Of Borrowed Empire |

## Save Data Shape

Suggested save fields:

```gdscript
var thieving_trophies := {
	"complimentary_spoon": {"stolen": false, "cooldown_until_unix_msec": 0},
	"crown_jewel_replica_replica": {"stolen": false, "cooldown_until_unix_msec": 0},
	"bad_decisions_idol": {"stolen": false, "cooldown_until_unix_msec": 0},
	"borrowed_empire_crown": {"stolen": false, "cooldown_until_unix_msec": 0}
}
```

The hub Trophy Case level can be derived from the highest stolen trophy tier. That avoids save drift between `hub_modules["trophy"].level` and trophy ownership.

## Implementation Notes

- Keep attempts deterministic enough to save immediately after roll resolution.
- Save before and after setting cooldown/trophy state so mobile app pauses do not duplicate rewards.
- Do not require a full reflex minigame for launch. The staged reveal gives enough drama with much less UI risk.
- Add trophy art as a separate transparent spritesheet if possible, so the same trophy image can appear in the heist card, reward popup, and hub Trophy Case.
- If new SFX are added, keep trophy success quieter than the main level-up jingle and avoid stacking multiple reward sounds.
