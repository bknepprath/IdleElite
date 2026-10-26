# Soft interaction guidance

Implemented locally on October 24, 2026.

- Firepit and jail share the existing curved red arrow, with a slow eight-pixel horizontal drift and a quarter-second reveal
- Cues ignore input, stay clear of their target artwork/text, and hide behind modals, during skill swipes and outside the clipped scroll region
- A real firepit tap or successful jail reduction dismisses that interaction's cue; the two independent flags survive save restoration
- The former blocking Firepit explanation has been replaced by the local arrow
- An empty Firepit reports “You need one scrap wood to light the fire.” in a two-line float; lighting with fuel still works
- Jail taps retain the green −1s float, now drawn above the bars and beside the timer inside the clipped card
- Ordinary Thieving activities stop causing jail at five skill levels above unlock; trophy heist cooldowns retain their separate rules

`scripts/test-soft-interaction-guidance.ps1 -VisibleGame` passed with the production main scene, real menu navigation and actual firepit/jail taps. It covers first interaction, nonblocking input, modal and offscreen hiding, fuel failure/success, exact one-second reduction, every ordinary activity's four/five-level boundary, save serialization/restoration, malformed flags and remounted cards.

Additional passes: `test-save-normalization.ps1`, `test-woodcutting-firepit.ps1`, `check-activity-database-contracts.ps1`, `audit-activity-database.ps1`, `check-activity-ui-boundary-contracts.ps1`, `check-runtime-asset-paths.ps1`. Database warnings describe existing nonmonotonic activity curves. The main-scene test emitted only the known Windows certificate-store warning. The save-normalization harness also emitted its permitted shutdown RID/ObjectDB warnings. No Godot process remained after testing.

Raw production viewport captures, all verified at 1080 × 1920:

- [Firepit first cue](../../outputs/verification/soft-guidance-oct24/firepit-before.png)
- [Firepit cue motion](../../outputs/verification/soft-guidance-oct24/firepit-arrow-motion.png)
- [Empty firepit tap](../../outputs/verification/soft-guidance-oct24/firepit-no-wood.png)
- [Lit firepit after tap](../../outputs/verification/soft-guidance-oct24/firepit-lit.png)
- [First jail cue](../../outputs/verification/soft-guidance-oct24/jail-before.png)
- [Jail tap feedback](../../outputs/verification/soft-guidance-oct24/jail-tap-feedback.png)
- [Jail after feedback fades](../../outputs/verification/soft-guidance-oct24/jail-after.png)

No export, device install or publication was performed.
