# Fighting Progression

This first implementation focuses on the early `Fight` skill while the other starter skills are still being rebuilt.

## Runtime Shape

- `scripts/main.gd` owns the current combat loop and keeps enemy tuning in the `ENEMIES` table.
- Save data uses `user://idle_elite_save.json`.
- Offline progress currently restores Fight stamina only.
- Global level is temporarily equal to Fight level until Thieving, Build, Woodcutting, and Fishing are implemented.

## Animal Ladder

| Unlock Level | Enemy | HP | Damage | Stamina | Hit Chance | Rewards |
| ---: | --- | ---: | ---: | ---: | ---: | --- |
| 1 | Chicken | 12 | 1-3 | 1 | 86% | 28 XP, $14 |
| 2 | Rat | 20 | 2-5 | 2 | 80% | 64 XP, $34 |
| 3 | Rabbit | 32 | 3-7 | 3 | 74% | 120 XP, $72 |
| 5 | Goat | 58 | 4-10 | 4 | 68% | 230 XP, $145 |
| 7 | Cow | 92 | 7-15 | 6 | 62% | 420 XP, $290 |
| 9 | Pig | 140 | 9-18 | 7 | 60% | 620 XP, $460 |
| 11 | Sheep | 190 | 11-22 | 8 | 58% | 860 XP, $690 |
| 13 | Goose | 255 | 14-28 | 9 | 56% | 1.20K XP, $980 |
| 15 | Emu | 340 | 17-34 | 10 | 54% | 1.68K XP, $1.45K |
| 18 | Boar | 470 | 22-44 | 12 | 52% | 2.50K XP, $2.30K |
| 21 | Horse | 640 | 28-54 | 14 | 50% | 3.60K XP, $3.50K |
| 24 | Bull | 860 | 36-68 | 16 | 48% | 5.20K XP, $5.40K |
| 28 | Bear | 1180 | 46-86 | 19 | 46% | 7.80K XP, $8.50K |

Hit chance gains a small bonus when the player's Fight level is above an enemy's unlock level. Misses grant grit XP so spent stamina always moves the player forward.

## Balance Intent

- Chicken and Rat should make the first level-up arrive quickly.
- Rabbit introduces visible HP attrition without becoming a wall.
- Goat asks the player to use more stamina per fight and benefits from early leveling.
- Cow is the first sturdy wall and should feel like the first heavy animal roadblock.
- Pig, Sheep, Goose, and Emu stretch the midgame through denser stamina spends.
- Boar, Horse, Bull, and Bear form the first long-tail progression band before stranger enemies arrive.

## Asset Direction

The starter ladder uses `docs/assets/enemies/starter-enemies.png`; the extended ladder uses `docs/assets/enemies/animal-progression-enemies.png`. Both sheets use plain, normal farm/field animals with thick black outlines and soft painterly shading.

Every sheet must be crop-safe: each animal lives fully inside one `724x724` square cell with green padding on all sides. Do not let antlers, horns, tails, snouts, feet, feathers, or ears cross into another frame.
