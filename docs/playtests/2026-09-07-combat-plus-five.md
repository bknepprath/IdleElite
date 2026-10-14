# Combat progression and XP at unlock plus five

Supersedes the level-99 calibration in `2026-09-07-combat-xp-rebalance.md`.

Combat strength now rises from unchanged unlock strength to 65% of the encounter's remaining strength progression over five levels, then increases gradually to the existing level-99 strength. This affects hero HP, damage, and attack interval together. Enemy health, attacks, animations, and knockout recovery remain unchanged. Dragons unlock at 98, so their calibration point is the level cap, 99.

Rewards use the measured kill and clear rate at unlock plus five. The target is 90% of the best available regular Fighting activity's expected XP/hour, including the time needed to recover its stamina. The baseline uses base XP, success probability, action duration, and the fastest unlocked Fighting recovery action. It excludes mastery, berries, food bonuses, and the separate rooster encounter. Existing earned XP is preserved.

| Encounter | Calibration level | Regular XP/hour | Combat target XP/hour | Independent measured XP/hour | Encounter XP budget |
| --- | ---: | ---: | ---: | ---: | ---: |
| Chickens | 10 | 5,914 | 5,322 | 5,580 | 151 |
| Goblins | 21 | 9,138 | 8,225 | 8,158 | 96 |
| R.O.U.S.es | 29 | 10,140 | 9,126 | 9,096 | 89 |
| Guys | 37 | 10,431 | 9,388 | 9,419 | 162 |
| Werewolves | 52 | 10,431 | 9,388 | 9,696 | 148 |
| Cave trolls | 64 | 11,784 | 10,606 | 10,404 | 351 |
| Giants | 79 | 16,489 | 14,840 | 14,784 | 605 |
| Vampires | 93 | 16,881 | 15,193 | 11,700 | 3,747 |
| Dragons | 99 | 16,881 | 15,193 | 14,523 | 1,431 |

Giants at level 79 now average 261 kills/hour (one every 14 seconds), versus 3.75 before the strength change. Cave trolls at level 64 average about 348 kills/hour after subtracting clear reward events, versus zero before. A giant kill pays 56 or 57 XP, with fractional credit carried between kills. Full encounter budgets are not individual monster payouts.

Vampires have fewer, slower kills and greater sample variation: the calibration seeds predicted 15,193 XP/hour, while the independent seeds measured 11,700. These estimates do not imply identical rewards in every short session. Higher-level characters can earn faster than the calibration target; level 99 is no longer the rate used to set rewards.

Validation uses 16 seeded three-minute samples per tested level, with different seed sets for calibration and acceptance. It checks unlock, unlock plus five, an intermediate level, and 99 (deduplicated), for 544 samples per full audit. Unlock-level zero-kill samples are allowed; the intended hard unlock is not an XP calibration failure. The plus-five acceptance band allows sampling variance, and requires at least 30 reward events/hour. Progression comparisons allow 15% variation between sampled rates.

Database contracts and the activity database audit passed. Runtime evidence is in `.codex-tmp/combat-plus-five-verified.log`. Live production-scene evidence is recorded separately in `.codex-tmp/combat-plus-five-live.log` and `.codex-tmp/combat-plus-five/`.

Live verification passed: native encounter buttons started cave trolls at Fighting 64 and giants at Fighting 79; both earned kills within 45 seconds. Captured rewards were +29 XP and +56 XP respectively. Raw viewport PNGs are 1080 by 1920. The test process exited cleanly; no agent-owned Godot process remained.
