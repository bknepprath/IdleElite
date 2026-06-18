# Idle Elite Animal Progression Enemy Assets
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


`animal-progression-enemies.png` extends the plain animal Fight ladder.

## Sheet

- File: `assets/content/enemies/animal-progression-enemies.png`
- Alpha runtime copy: `assets/content/enemies/animal-progression-enemies-alpha.png`
- Source/reference copy: `assets/content/enemies/animal-progression-enemies-source.png`
- Size: `5792x724`
- Cell size: `724x724`
- Background: flat chroma green.
- Crop rule: every animal must fit fully inside its own `724x724` square cell with green padding on all sides. No body part may cross into a neighboring frame.

## Frame Order

| Index | Enemy | Suggested tier |
| ---: | --- | --- |
| 0 | Pig | Level 9 farm animal |
| 1 | Sheep | Level 11 woolly animal |
| 2 | Bull | Level 24 heavy animal |
| 3 | Emu | Level 15 fast animal |
| 4 | Goose | Level 13 loud animal |
| 5 | Boar | Level 18 wild animal |
| 6 | Horse | Level 21 large animal |
| 7 | Bear | Level 28 apex animal |

Frame `x` offset is `index * 724`.
