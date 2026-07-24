# Fight monster real-game proof manifest

Date: 2026-07-19  
Viewport: 1080x1920 portrait  
Result: **PASS for all seven replacement sets.** The arena crops below are pixel-identical crops of the listed real Godot captures; they are not mockups or reconstructed renders.

| Monster | Runtime proof | Source capture SHA-256 | Crop SHA-256 | Verified state |
| --- | --- | --- | --- | --- |
| Chicken | `chicken-arena-proof.png` | `0B350D0ECD85516570345230E7A1AAC9962456159BCDD749C8671D4B7F60C5BC` | `6546BF3E578C1113F1161A8952CFC817C2D685A08529FCE105A8F153B461854C` | Multiple current white Chicken bodies at the calibrated compact scale; aligned, unclipped, canonical direction mirrored by runtime. |
| Goblin | `goblin-arena-proof.png` | `F46C520FCB7FA273BBAB5DB0D608B4A668D749FBC0BDD4A7514CF2DCCC0F5666` | `DA892FBD2276A5F84A0838526E6E0280152848A065121EA2779870CA9CE66CA5` | Current shielded and defeated Goblin bodies at peer scale; no legacy detailed-face sprite is present. |
| Rouse | `rouse-arena-proof.png` | `8A13AF8D7E0DC52D25F969640D46CED7BBA8AFCE1AE3531E5F5820771E7D01B5` | `54464CC28E0F9FB83E210813DE523ED79AFA01CB2AA7EF6543A1F4C11D084A38` | Current crash/stagger body at the calibrated heavy scale with a separate dizzy-star loop; correct anchor and no clipping. |
| Werewolf | `werewolf-arena-proof.png` | `EC11589D7B90E017D2684F63E99036B4117EA4819637CCF9B552C1A6F2F59705` | `20EA98F2C1482B57C035E720F4457E20C736BAD510949683A829AA55E305EE2D` | Current close-combat body; larger than the hero, with correct baseline, facing, and health-bar anchor. |
| Werewolf transform | `werewolf-transform-arena-proof.png` | `32B4105645B9A196D3B3A678AD3945D9789005AA7A61B9469EE0769E646B4C12` | `CB1C261EED0ED0C6AE666157FBE0CDEADD1673CB15F3613D2571E26380C18ADC` | Natural Orange Guy-to-Werewolf midpoint at the corrected scale; aligned, unclipped, correctly facing, and free of baked VFX. |
| Cave Troll | `cave-troll-arena-proof.png` | `EA463142AB753EB433397EE263A3F01CD762F8E962780725F7E477D63D191DDE` | `32FB835FE561825E8F631D82DB8BDE6E9823448C97FDB765546D78A87240B0DE` | Current slam body at the calibrated heavy scale with an independently placed ground-impact asset. |
| Vampire | `vampire-arena-proof.png` | `CACA940FF9DDB93F5158DD17B1483F3724187198310F2E574F2CF3666A18BE36` | `B1461631669BA93E1C83C2DD64E69A7BFD531BCC48462521B9C3E85DEC2416B4` | Current flank-cross attack body at peer scale; aligned, unclipped, and correctly facing. |
| Dragon | `dragon-arena-proof.png` | `6E60C5B87DFA13ED0DF52D6702B314B1DE9911EF4A98B88EBEA88D18A9725037` | `3821908A42F52D4ACF1C38B9BA18CB4693CBDBD4A48EBD1F2DFB4588E7177E1B` | Current breath body is the largest monster; the independent flame begins at the mouth and remains distinct from the body frame. |

## Source captures

- `.codex-tmp/fighting-diamond-real/fight-chickens-lv99-auto-real-card-active-runtime-scale-final-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-goblins-lv99-auto-real-card-active-runtime-scale-final-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-r-o-u-s-es-lv99-rouses-crash-real-card-active-runtime-behavior-final-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-werewolves-lv99-auto-real-card-active-runtime-scale-final-wolf-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-werewolves-lv99-werewolf-transform-real-card-active-runtime-scale-final-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-cave-trolls-lv99-cave-troll-slam-real-card-active-runtime-behavior-final-v2-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-vampires-lv99-vampire-flank-cross-real-card-active-runtime-behavior-final-1080x1920.png`
- `.codex-tmp/fighting-diamond-real/fight-dragons-lv99-breath-strike-real-card-active-runtime-behavior-final-1080x1920.png`

## Validation summary

- Mechanical asset audit: `tmp/validation/fight-monster-assets/audit.md` — PASS, zero findings.
- Fight-specific Godot behavior probe: `fighting-diamond-arena-ok`; every included state, movement, attack, support, transform, and VFX path is checked against the current source PNG bytes.
- Runtime art loading prefers the current source PNG before the import cache, preventing stale imported body frames from mixing with current action frames.
- Calibrated scale hierarchy: Chicken compact; Goblin/Vampire peer-sized; Rouse/Werewolf/Cave Troll heavy; Dragon largest. Guy and Giant scale values remain unchanged.
- Broad `scripts/check-project.ps1`: reached an unrelated existing navigation-shell/module-list failure (`_find_named_control_descendant` and pinned utility-tab fill mismatch). No fight-asset failure was reported.
- No tracked fight `.import` sidecar was dirtied by the validation run. Pre-existing unrelated deleted AdMob `.import` files were preserved.
- Guy and Giant remain outside the replacement scope.
