# Fight monster asset audit — final-final

Date: 2026-07-19  
Mode: read-only production audit.

## Result

**PASS — zero mechanical findings.**

## Checks

- 7/7 approved base-model SHA-256 hashes match exactly.
- 112/112 runtime body frames exist, are 512×512 RGBA, retain partial alpha, and have alpha bounds within `x=32..479`, `y=32..448`.
- 11/11 intentional masters exist and are 2048×1536 RGBA.
- Dragon’s intentional masters all pass: `fight-dragons-main-master.png`, `fight-dragons-claw-master.png`, and `fight-dragons-breath-master.png`.
- Dragon claw frames pass normal color-distribution checks; no white-interior corruption detected.
- 16/16 standalone VFX frames pass required dimensions, RGBA/partial-alpha, and non-opaque-background checks.
- Dizzy-star center region `(96,96)-(160,160)` is transparent in all four frames.
- Chicken white/gray/black corresponding alpha silhouettes match.
- Every production-referenced PNG path resolves.
- Movement uses four frames at `MOVEMENT_FPS := 6.0`.
- Attack mapping, canonical screen-right map, true dizzy selection during stagger, Rouse dizzy queue, and VFX loading from `assets/content/fight/effects/` pass.
- Guy/Giant remained excluded and untouched by this audit.

Production art and gameplay code were not edited; only this report was overwritten.
