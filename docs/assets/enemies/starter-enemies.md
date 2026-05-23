# Starter Enemy Assets

`starter-enemies.png` is a plain regular-animal starter Fight enemy sheet.

## Sheet

- File: `docs/assets/enemies/starter-enemies.png`
- Source/reference copy: `docs/assets/enemies/starter-enemies-source.png`
- Size: `3620x724`
- Cell size: `724x724`
- Background: flat chroma green, matching the existing enemy and character sheet convention.
- Style: ordinary farm/field animals with clean cartoon outlines and soft shading.
- Crop rule: every animal must fit fully inside its own `724x724` square cell with green padding on all sides. No body part may cross into a neighboring frame.

## Frame Order

| Index | Enemy | Suggested tier |
| ---: | --- | --- |
| 0 | Chicken | Level 1 tutorial target |
| 1 | Rat | Level 2 cellar pest |
| 2 | Rabbit | Level 3 quick target |
| 3 | Goat | Level 5 farm animal |
| 4 | Cow | Level 7 heavy animal |

Frame `x` offset is `index * 724`.
