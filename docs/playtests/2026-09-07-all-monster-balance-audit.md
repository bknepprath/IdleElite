# All playable monster balance audit

Uses the revised unlock-plus-five progression. All nine enabled diamond encounters are included. The separate rooster boss is disabled in the activity database and is excluded from playable XP comparisons.

Method: 16 independent five-minute seeds per tested level, using a new seed set. Each encounter is measured at unlock, unlock plus five, midpoint, and level 99, with duplicates removed. This is 544 samples and 45 hours 20 minutes of simulated combat. The regular-training benchmark includes expected success and stamina recovery time; mastery, berries, and other bonuses are excluded. Dragons use level 99 because their unlock is 98.

| Monster | Level | XP/hour | Regular training XP/hour | Training ratio | Kills/hour | Knockouts/hour |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Chickens | 10 | 5,450 | 5,914 | 92% | 2,028 | 72 |
| Goblins | 21 | 8,471 | 9,138 | 93% | 1,688 | 0 |
| R.O.U.S.es | 29 | 8,935 | 10,140 | 88% | 1,358 | 0 |
| Guys | 37 | 9,587 | 10,431 | 92% | 7,523 | 0 |
| Werewolves | 52 | 9,685 | 10,431 | 93% | 883 | 33 |
| Cave Trolls | 64 | 10,230 | 11,784 | 87% | 346 | 139 |
| Giants | 79 | 13,712 | 16,489 | 83% | 242 | 98 |
| Vampires | 93 | 12,872 | 16,881 | 76% | 41 | 65 |
| Dragons | 99 | 11,263 | 16,881 | 67% | 63 | 139 |

## Full progression measurements

| Monster | Fighting level | XP/hour | Kills/hour | Clears/hour | Knockouts/hour |
| --- | ---: | ---: | ---: | ---: | ---: |
| Chickens | 5 | 764 | 286.5 | 0.0 | 264.8 |
| Chickens | 10 | 5,450 | 2,028.0 | 0.0 | 72.0 |
| Chickens | 52 | 7,552 | 2,451.0 | 16.5 | 55.5 |
| Chickens | 99 | 12,813 | 2,902.5 | 84.0 | 0.0 |
| Goblins | 16 | 159 | 50.2 | 0.0 | 339.8 |
| Goblins | 21 | 8,471 | 1,687.5 | 84.0 | 0.0 |
| Goblins | 58 | 9,241 | 1,729.5 | 96.0 | 0.0 |
| Goblins | 99 | 9,347 | 1,774.5 | 96.0 | 0.0 |
| R.O.U.S.es | 24 | 39 | 7.5 | 0.0 | 364.5 |
| R.O.U.S.es | 29 | 8,935 | 1,357.5 | 96.0 | 0.0 |
| R.O.U.S.es | 62 | 9,360 | 1,413.8 | 101.2 | 0.0 |
| R.O.U.S.es | 99 | 9,755 | 1,495.5 | 108.0 | 0.0 |
| Guys | 32 | 283 | 383.2 | 0.0 | 345.0 |
| Guys | 37 | 9,587 | 7,523.2 | 57.8 | 0.0 |
| Guys | 66 | 9,744 | 7,632.8 | 59.2 | 0.0 |
| Guys | 99 | 9,744 | 7,632.8 | 59.2 | 0.0 |
| Werewolves | 47 | 54 | 6.0 | 0.0 | 273.8 |
| Werewolves | 52 | 9,685 | 882.8 | 49.5 | 33.0 |
| Werewolves | 73 | 11,348 | 1,029.8 | 69.8 | 5.2 |
| Werewolves | 99 | 12,850 | 1,174.5 | 84.0 | 0.0 |
| Cave Trolls | 59 | 87 | 3.0 | 0.0 | 278.2 |
| Cave Trolls | 64 | 10,230 | 346.5 | 1.5 | 138.8 |
| Cave Trolls | 79 | 14,245 | 464.2 | 13.5 | 90.8 |
| Cave Trolls | 99 | 25,022 | 792.0 | 61.5 | 18.0 |
| Giants | 74 | 253 | 4.5 | 0.0 | 205.5 |
| Giants | 79 | 13,712 | 242.2 | 0.0 | 98.2 |
| Giants | 87 | 15,538 | 274.5 | 0.0 | 85.5 |
| Giants | 99 | 22,463 | 393.8 | 2.2 | 71.2 |
| Vampires | 88 | 2,340 | 7.5 | 0.0 | 79.5 |
| Vampires | 93 | 12,872 | 41.2 | 0.0 | 65.2 |
| Vampires | 94 | 14,746 | 47.2 | 0.0 | 66.0 |
| Vampires | 99 | 27,860 | 84.0 | 1.5 | 48.8 |
| Dragons | 98 | 11,932 | 66.8 | 0.0 | 131.2 |
| Dragons | 99 | 11,263 | 63.0 | 0.0 | 138.8 |

Evidence: `.codex-tmp/all-monster-balance-audit.log`. The simulation executes the production combat stage, including knockout restarts, area clears, attack randomness, healing, and reward distribution. It is not a visual playtest.

## Findings

- Chickens, goblins, R.O.U.S.es, Guys, werewolves, and cave trolls are within 87–93% of regular training at the calibration level. Giants are slightly lower at 83%.
- Vampires (76%) and dragons (67%) are the clearest candidates for further tuning. Their infrequent kills and knockouts make short-session returns variable. Dragons also have no five-level runway before the cap; their level-99 sample did not outperform level 98, so XP changes alone will not establish a satisfying progression.
- Cave trolls and dragons still suffer about 139 knockouts/hour at the calibration point, roughly one every 26 seconds. Their XP can be acceptable while the experience remains interruption-heavy.
- At level 99, cave trolls, giants, and vampires earn substantially above the best base regular-training benchmark (16,881 XP/hour). The stronger-character benefit was explicitly retained, so these are economy tradeoffs to review rather than automatic test failures.
- No encounter shows the previous giant-sized per-kill payout: current giant kills are 56–57 XP, vampires 312–313, and dragons 178–179. Encounter-clear bonuses are additional.

The audit passed its broad regression bands. That does not mean all encounters meet the narrower 90% design target. No reward or difficulty values were changed in this audit. The next focused tuning should address vampire consistency and dragon endgame difficulty, preserving the intended hard unlocks for the other encounters.
