# Production building shape

Implemented locally on October 24, 2026.

Shape Wooden Parts now uses the regular activity portrait, stats, mastery treatment and progress rail, with a compact 4 Softwood → 2 Wooden Parts recipe row. Its face height is 400px, down from the previous 560px stage. The existing recipe ID, materials, costs, rewards and save keys remain unchanged.

The nine Building recipes marked `presentation.building` share a sharp centered inward V cut: Melt Sand, Shape Bottles, Make Candles, Grind Lens, Shape Wooden Parts, Mix Fishing Bait, Assemble Spyglass, Assemble Lantern and Weave Selective Net. The same 64px notch depth and half-width define the face, rail and rear plate. The notch is transparent; no page-colored cover is used. Idle rear plates redraw only when their front face moves or their size changes. Other building stages retain their layouts, with fixed space and a canonical 202px actor box reserved below the title and above the recipe/stats/cut. Recovery cards retain their existing convex shape.

Validation passed:

- Real `scenes/main.tscn`, reached through actual skill-menu and activity taps, with all nine buildings captured before, during, working and after stopping
- Spyglass assembly completed and its real Scout control remained functional
- `scripts/test-production-paths.ps1`, including production accounting, save/offline behavior and medal strategy regressions
- `scripts/test-recovery-modules.ps1`
- Activity database contracts and content audit, activity UI boundaries, runtime asset paths and `git diff --check`

Final raw viewport captures are in `outputs/verification/production-shape-oct24/final/`: 38 PNGs, all verified at 1080 × 1920. The visible main-scene run emitted only the known Windows certificate-store warning. The recovery unit harness also emitted its permitted shutdown RID/resource warnings. No Godot process remained after the checks. No export or publication was performed.

- [Wooden Parts idle](../../outputs/verification/production-shape-oct24/final/carve-spyglass-tube-before.png)
- [Wooden Parts transition](../../outputs/verification/production-shape-oct24/final/carve-spyglass-tube-transition.png)
- [Wooden Parts working](../../outputs/verification/production-shape-oct24/final/carve-spyglass-tube-working.png)
- [Wooden Parts after stopping](../../outputs/verification/production-shape-oct24/final/carve-spyglass-tube-settled.png)
- [Melt Sand](../../outputs/verification/production-shape-oct24/final/melt-sand-before.png)
- [Spyglass](../../outputs/verification/production-shape-oct24/final/assemble-spyglass-before.png)
- [Selective Net](../../outputs/verification/production-shape-oct24/final/weave-selective-net-before.png)
