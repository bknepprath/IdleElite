# October 22 action-art audit

The source review covers all 173 permanent activity definitions and five temporary events. The production UI sweep captured 177 reachable entries; the disabled Rooster action was reviewed from its source but is not presented as a live-game capture.

Each action now has authored `art_framing` data with one fixed zoom and focal position. The rounded portrait mask clips secondary scenery at the edge. Animated actions keep exactly the same framing across all frames; atlas regions affect UV addressing only. No alpha-bound measurements determine animation scale.

Practice Kicking uses a newly generated smooth blue figure with continuous rounded limbs, mitten hands, and no mud, ground or effects. The existing serialized `kick-mud-off-boot` action ID is preserved. Runtime art is `assets/content/fight/actions/practice-kicking.png`; generation provenance and hashes are in `outputs/art/practice-kicking-oct22/`.

The owner corrected medal occlusion during review. Loot a Pirate Ship keeps its 1.15 zoom and moves down/right to focus [0.42, 0.43]. Thirty portrait corrections improve medal clearance and headroom, including the dock anchor, trophy oar, basic building work and recovery poses. Heads must not graze the top border. Deliberate cropping remains available for secondary scenery and props.

Validation:

- Complete real-main-scene sweep: 178 definitions accounted for, no assertion or script errors.
- Follow-up clearance sweep: all 30 corrected portraits passed.
- Every base proof PNG was checked as raw 1080x1920. Push-ups and Chameleon Camouflage also have raw transition and settled frames from their production run.
- Actual held swipe exposes the attached cached production portrait; mask and portrait containment checks passed, followed by the settled neighbouring skill.
- Database, UI-boundary, activity-UI-boundary, test-harness, crash and runtime-asset contracts passed. The success-base regression still passes all four profiles and next-tier medal checks.

Raw screenshots and their SHA-256 manifest: `H:/Codex/Projects/IdleElite/outputs/action-art-oct22/`. Per-action framing review: `outputs/art/action-audit-oct22/framing-review.json`. The source and runtime contact sheets there are internal inspection aids; they are not substituted for raw game proof.

This is focused visual validation. The earlier full-suite skills-page performance failure has not been cleared by this pass. No release export or physical Android acceptance is claimed.

The final owner correction gives Practice Kicking a fixed 0.82 zoom and focus [0.42, 0.45]. Both feet have visible padding and the head clears the medal. The focused production check passed. The latest raw portrait and desktop proofs are `kick-mud-off-boot-final-portrait.png` (1080x1920) and `kick-mud-off-boot-final-desktop.png` (1920x1080), in the raw screenshot directory. The horizontal preview is left running with muted monitoring and isolated, non-writing test state.
