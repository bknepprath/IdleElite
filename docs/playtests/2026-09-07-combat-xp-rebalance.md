# Combat XP and presentation revision

Removed negative red damage numbers for both the hero and enemies. Health bars, health stats, healing feedback, and XP rewards remain. Active diamond titles now draw before actors, so monsters obscure the title when they overlap it. Inactive portrait titles retain their existing position and outline.

## XP baseline

For each encounter's unlock level, compare eligible regular Fighting activities using:

`expected XP/hour = XP × success probability × 3600 / (activity seconds + stamina cost × recovery seconds per stamina)`

Recovery uses the fastest recovery activity available at that unlock level, or 12 seconds per stamina before a recovery activity unlocks. The comparison excludes animated encounters and the separate rooster encounter. It uses base activity values, without mastery, berries, food, or other bonuses. The combat target is 80% of the best eligible regular activity's adjusted rate. This is a conservative work-and-recovery benchmark, not a prediction of every player's sustained rate.

Each encounter now has a fixed XP budget: `reward_xp` and `par_reward_xp` are equal. Increasing Fighting level no longer multiplies the XP budget; stronger characters progress faster through fights. Existing saves and earned XP are preserved.

| Encounter | Regular baseline XP/hour | Target XP/hour | Measured level-99 XP/hour | Encounter budget |
| --- | ---: | ---: | ---: | ---: |
| Chickens | 1,485 | 1,188 | 1,148 | 14 |
| Goblins | 6,239 | 4,992 | 4,961 | 51 |
| R.O.U.S.es | 9,138 | 7,311 | 7,351 | 69 |
| Guys | 10,140 | 8,112 | 8,099 | 134 |
| Werewolves | 10,431 | 8,345 | 8,368 | 97 |
| Cave trolls | 11,784 | 9,427 | 9,405 | 132 |
| Giants | 12,205 | 9,764 | 9,731 | 246 |
| Vampires | 16,881 | 13,505 | 13,495 | 1,907 |
| Dragons | 16,881 | 13,505 | 13,491 | 1,271 |

The budget covers the complete encounter, not each monster. Giants distribute 184 XP across eight planned kills (23 each) and 62 on clearing the area. Previously, a level-99 giant kill paid approximately 1,537 XP.

Small fractional kill rewards now carry across knockout and round restarts within the stage, preventing early chicken kills from repeatedly rounding down to zero.

## Validation

The seeded rate audit uses 16 samples of 180 seconds at each tested level, 544 samples total. It checks positive rewards, mature sample progression, and the new rate bands. Sparse unlock-level samples are excluded from monotonic comparisons when either sample has fewer than 16 reward events; three versus six rare kills cannot establish a reliable trend.

Database contracts and the activity database audit passed. Live production-scene checks started Giants and Dragons via native touch, checked that no negative damage labels appeared, and captured raw 1080×1920 frames. `dragon-title-overlap.png` shows title occlusion with a deterministic actor position in the live production scene. `reward-fight-giants.png` captures the actual +23 XP reward.

Evidence: `.codex-tmp/combat-rebalance-credit.log`, `.codex-tmp/combat-rebalance-visible2.log`, and `.codex-tmp/combat-rebalance/`.
