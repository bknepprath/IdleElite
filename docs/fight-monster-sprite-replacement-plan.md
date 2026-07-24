# Diamond Fighting monster sprite replacement plan

Status: **complete**. Scoped replacement and verification are complete for Chicken (white/gray/black), Goblin, Rouse, Werewolf, Cave Troll, Vampire, and Dragon. Guy and Giant remain excluded and style-locked.

## Runtime contract

The renderer is `scripts/ui/blue_guy_chicken_brawl_stage.gd`. It loads Chicken assets from `assets/content/fight/prototype/`, the other families from `assets/content/fight/enemies/<family>/`, Dragon claw and breath frames, and four-frame independent effects. `_movement_texture()` selects movement and the five Werewolf transform frames; `_draw_chicken()` selects Chicken state, windup, movement, and attack; `_draw_goblin_shield()` draws the shield independently; `_draw_character_texture()` applies the shared scale/flip/rotation path. Gameplay timing remains in the existing stage logic and `scripts/gameplay/fighting_runtime.gd`.

All scoped runtime body, state, movement, attack, and special exports are 512x512 RGBA PNGs, screen-right, partial-alpha, planted at baseline y=448, with no baked hit VFX. Existing visually validated scale multipliers are retained: Chicken 1.90, Goblin 1.85, Rouse 2.70, Werewolf 2.10, Cave Troll 2.40, Vampire 2.05, Dragon 2.30.

The correct Dragon source is `tmp/imagegen/diamond-fight-base-models/approved-sources/dragon-goblin-approved-chroma.png`, SHA256 `EBA73146D7496048C600D30C32D0DE8745BEBCB8A38E7C8448E9E598F8FDDD7A`. Its transparent master is SHA256 `91C5A4883A8D36A058837499E1ADE6B6DFF27EBC995D0EED3DBBFF7369AB05A3`. Runtime `assets/content/fight/base-models/dragon-base.png` is SHA256 `DC33ECB8677C3A70C8860521FB727107E96CFC8F27DB83C72F8780007B0D24F8`: the compact right-facing olive quadruped from the user-supplied Goblin+Dragon magenta image. `scripts/test-fighting-diamond-arena.ps1` asserts this runtime hash.

## Monster matrix

| Monster | Runtime mapping | Final verification |
|---|---|---|
| Chicken swarm | `prototype/chicken(-gray|-black)-{idle,hit,dizzy,defeated}.png`; palette movement `chicken-white-move-01..04`, `chicken-{gray,black}-move-01..04`; palette attacks `chicken(-gray|-black)-attack-01..04`; existing windup and cover support remain mapped. | White, gray, and black movement/state/attack/windup/cover paths pass. Twelve stale unhyphenated compatibility files were overwritten byte-for-byte from approved hyphenated counterparts: white move01..04, gray attack01..04, black attack01..04. All pairs hash-equal; compatibility paths remain and nothing was deleted. |
| Goblin | `enemies/goblins/goblins-{idle,hit,dizzy,defeated}.png`, `goblins-move-01..04.png`, `goblins-attack-01..04.png`. | Runtime art audit passes. `goblin-shield` remains an independent overlay and shield fall is runtime motion. |
| Rouse | `enemies/rouses/rouses-{idle,hit,dizzy,defeated}.png`, `rouses-move-01..04.png`, `rouses-attack-01..04.png`. | Runtime art audit passes, including wall crash, dizzy stars, and recovery. |
| Werewolf | `enemies/werewolves/werewolves-{idle,hit,dizzy,defeated}.png`, `werewolves-move-01..04.png`, `werewolves-attack-01..04.png`, `werewolves-transform-01..05.png`. | All normal frames and transform frames pass. Transform-01 and -02 were replaced; transform-03..05 are unchanged. |
| Cave Troll | `enemies/cave-trolls/cave-trolls-{idle,hit,dizzy,defeated}.png`, `cave-trolls-move-01..04.png`, `cave-trolls-attack-01..04.png`. | Runtime art audit passes. Slam remains independent and triggers once at ground contact. |
| Vampire | `enemies/vampires/vampires-{idle,hit,dizzy,defeated}.png`, `vampires-move-01..04.png`, `vampires-attack-01..04.png`. | Runtime art audit passes. Smoke remains procedural and flank/vanish timing is unchanged. |
| Dragon | `enemies/dragons/dragons-{idle,hit,dizzy,defeated}.png`, `dragons-move-01..04.png`, `dragons-claw-01..04.png`, `dragons-breath-01..04.png`. | All states, movement, claw, and breath frames pass. Correct compact Dragon and separate breath flame pass real capture review. |

Source/master sheets and previews are authoring evidence, not runtime substitutes.

## Independent VFX matrix

| Effect | Runtime contract |
|---|---|
| `hit-impact-yellow-01..04.png` | Independent contact effect; no body frame contains it. |
| `dizzy-stars-01..04.png` | Independent Rouse/generic stagger effect. |
| `dragon-breath-flame-01..04.png` | Independent, direction-oriented flame effect; not baked into Dragon. |
| `cave-troll-slam-01..04.png` | Independent ground-centered slam effect; not baked into Troll. |

Goblin shield remains independent; Vampire smoke remains procedural. Hit markers, stars, slash, flame, dust, smoke, glow, streaks, debris, feathers, and particles are not baked into body or attack sprites.

## Acceptance checklist

- All seven scoped monsters have intentional runtime mappings for states, movement, attacks/specials, and required transforms/palettes.
- Runtime exports are 512x512 RGBA, right-facing, partial-alpha, baseline y=448, and free of baked hit VFX.
- Existing family scale multipliers are retained after visual validation.
- Chicken compatibility paths are retained and independently hash-equal to approved hyphenated counterparts.
- Independent VFX and procedural effects remain separate from monster art.
- Guy and Giant remain excluded/style-locked.
- `scripts/test-fighting-diamond-arena.ps1` final run passes with `fighting-diamond-arena-ok`, zero new headless processes, and zero new tracked import status.

## Final verification and evidence

Werewolf transform hashes and alpha boxes:

- `werewolves-transform-01.png`: SHA256 `3F9E592ECD7BA1AA959ACD739B38722540B831C767A7F3E6AFF651295C9B1A9E`, bbox `(63,57,448,448)`, partial alpha 5858.
- `werewolves-transform-02.png`: SHA256 `0B9A01FD7925DC44AB024E2B77E6851E24421320FDEA7B2980F6AE81306D87A9`, bbox `(72,62,440,448)`, partial alpha 5825.
- Unchanged frames 03-05: `7425A151A193F28DAE22B42A5D4FE85BD08D796D5FF3025AD2F0ABE68E802791`, `4B1C082AE69B59B26CE202C82F1B823F6DB27C2DF1D434C09644DEFF6E18C4A3`, `501B81DEA04C4B0F37F61EA2F2968F44C3508A41D08DD34E61DC5598DA017EBE`.

Real 1080x1920 visible-game completeness captures passed for every scoped monster. Final changed-frame proof is `.codex-tmp/fighting-diamond-real/fight-werewolves-lv99-werewolf-transform-real-card-active-transform-frame02-final-1080x1920.png`, SHA256 `DCEC9F3594D2B9B59799C02549DE99DE2B068A10A1EE7D153A9E752DF1F2AA5E`; cue log `transform_timer=0.633` and, after settle, transform frame02. Tight crop: `.codex-tmp/fighting-diamond-real/crops/fight-werewolves-lv99-werewolf-transform-real-card-active-transform-frame02-final-1080x1920-werewolf-tight.png`.

Dragon proof: `.codex-tmp/fighting-diamond-real/crops/fight-dragons-lv99-breath-strike-real-card-active-monster-scale-audit-1080x1920-arena-tight.png`, showing the correct compact Dragon and separate flame effect.

The capture harness Werewolf cue window is now greater than 0.56 and less than 0.64, so proof holds frame02 after two render frames. Gameplay transform duration remains 0.80 and is unchanged.
