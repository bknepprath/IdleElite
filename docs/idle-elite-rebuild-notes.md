# Idle Elite Rebuild Notes

Source page: https://www.kongregate.com/en/games/brian4/idle-elite

## Public Kongregate Facts

- Title: `Idle Elite`
- Developer: `Brian4`
- Released: July 22, 2012
- Last updated: July 28, 2012
- Rating shown on Kongregate: `2.2`
- Tags: `Idle`, `Cute`, `Dress Up`, `Emo`, `Music`, `Defense`, `Strategy`
- How to play: `Mouse, then idle.`
- Final listed version: `v0.0.7.0`
- Original source files were deleted, according to the May 8, 2013 developer update.

## Original Build / Runtime

- Kongregate game id: `150609`
- Native game size: `750x600`
- SWF file: `idle14.swf`
- SWF signature/version: `CWS`, version `7`
- Original title screen text: `I MUST BECOME AN IDLE ELITIST!`
- Title screen visual identity: stark white canvas, heavy black display text, stick figure with large shaded head, simple handmade Flash-era UI.

## Recovered Core Loop

Idle Elite was not a pure clicker. It was closer to a tiny skill/job idle game.

Primary global values:

- `lvl`
- `cash`
- `earn`
- `earncost`
- `earnbuys`

Skills/jobs:

- `Fight`
- `Thieving`
- `Build`

Each skill had:

- Level
- XP
- Stamina
- Max stamina

The overall level was calculated as:

```text
lvl = thievinglvl + buildlvl + fightlvl
```

The idle tick did:

```text
cash += earn
earn += 1
earncost = earn * 5 - lvl * 2 + earnbuys * 100
```

Stamina regenerated over time. Max stamina used:

```text
max_stamina = 10 + skill_level * 5
```

## Job Actions

Each job had three action tiers:

- Level 1 action: available immediately
- Level 2 action: requires skill level above 1
- Level 3 action: requires skill level above 2

When an action was pressed, it consumed all current stamina for that skill in a loop. Each stamina point rolled:

```text
trainchance = random(100) + 1
success if trainchance > 33
```

So the success chance was about 67%.

Reward table:

| Action tier | XP on success | Cash on success |
| --- | ---: | ---: |
| Level 1 | 5 | 100 |
| Level 2 | 10 | 400 |
| Level 3 | 20 | 800 |

The job labels in the SWF were:

- Fight: `Fight`
- Thieving: `Rob`
- Build: `Build`

## Level Thresholds

The game used the same XP thresholds for each job:

| XP Range | Level |
| ---: | ---: |
| 0-399 | 1 |
| 400-1299 | 2 |
| 1300-2699 | 3 |
| 2700-4799 | 4 |
| 4800-7599 | 5 |
| 7600-11199 | 6 |
| 11200-15699 | 7 |
| 15700-21099 | 8 |
| 21100-27599 | 9 |
| 27600-35199 | 10 |

## Original Screens

- Title screen with a large `Play` button.
- Main hub showing `LVL`, `CASH`, `EARNING`, with navigation buttons for `THIEVING`, `BUILD`, and `FIGHT`.
- Fight screen with three `Fight` buttons, level gates, stamina, XP, max stamina, level, and `BACK`.
- Thieving screen with three `Rob` buttons, level gates, stamina, XP, max stamina, level, and `BACK`.
- Build screen with three `Build` buttons, level gates, stamina, XP, max stamina, level, and `BACK`.
- Shop/earn screen with text `Earn More` and `Price:`.

## Rebuild Direction

Keep the recognizable structure:

- Character wants to become an `Idle Elite`.
- Three starter jobs: Fight, Thieving, Build.
- Stamina-gated actions.
- XP and level progression per job.
- Global level as the sum of job levels.
- Passive cash/earning loop.
- Earn-rate shop.

Modernize for mobile:

- Rename the project away from the placeholder `Idle Slop`.
- Use a portrait layout with bottom tabs for Jobs, Gear, and Hero.
- Keep the handmade charm, but replace the harsh empty Flash layout with polished panels, readable mobile typography, animation, and clear progress bars.
- Split activities into idle actions with a single `Start` button and active actions with one clear verb, such as `Chop` or `Pick Lock`.
- Add offline progress, achievements, prestige, and ad rewards later.

Monetization-friendly expansion:

- Rewarded ad: double offline earnings.
- Rewarded ad: refill one skill's stamina.
- Rewarded ad: temporary success chance boost.
- Optional interstitial only after major milestones, never after every tap/action.
