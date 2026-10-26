# Grove gold leaves, October 25

Follow-up: the original 56px size below was superseded by a 36px draw box and individual tree anchors. See `2026-10-25-grove-leaf-clearance.md` for current placement and outline validation.

Replaced the star markers with a simple stemless leaf silhouette in one solid gold fill, with no outline, vein, highlight, shadow or gradient. The accepted production asset is `assets/content/woodcutting/groves/gold-leaves.svg`: two mirrored copies of the same shape in 256px cells, rendered in fixed 56px draw boxes. The first generated illustrated sheet was rejected by the owner and is archived under an ignored output directory, outside the production assets.

Source rules for every grove now define three conditional bonus levels. One leaf gives +25% logs, two +75%, three +200% (the previous full triple harvest). Among bonus-tree rolls, the weights are 60/30/10. Existing Luck chance and purchased upgrades remain unchanged. Normal trees show no leaves. Markers stay attached through sway, fall and fade, and do not pulse independently.

Fractional multipliers use an ordinary base-log roll followed by stochastic rounding of the scaled amount. This preserves the intended mean instead of rounding every small harvest upward. Tree health, skill XP, axe XP and stamina cost are unchanged by the new levels. Each harvest burst still contains exactly the number of logs actually awarded.

Save version 5 persists `gold_leaves` per tree. Existing saved bountiful trees without that field retain three leaves and their full bonus. New levels survive JSON save/restore and remain bounded to 1–3 for bonus trees; normal trees restore zero. No phone install, save replacement or release publication was performed for this change.

Validation passed:

- `grove_gold_levels.gd`: 216000 sampled harvests across six groves and three levels, reward bounds and mean output, weighted level rolls, unchanged health/XP, all-level roundtrip and legacy full-bonus compatibility
- `groves_and_range.gd`: existing gameplay, spending, harvest, duplicate-payment prevention and save regressions
- Required database contracts and activity audit
- Real main scene reached through actual Woodcutting navigation, all six tree types with normal/one/two/three-leaf examples, then actual start/fall/harvest interaction
- Required Woodcutting screen audit

Raw 1080x1920 captures: `outputs/verification/grove-flat-gold-leaves-oct25/`. Each grove's `*-leaf-levels.png` shows normal, one, two and three leaves from left to right. `leaves-standing.png`, `leaves-follow-falling-tree.png` and `leaves-cleared-after-harvest.png` come from the same actual-main run. No agent-owned Godot process remained afterward.
