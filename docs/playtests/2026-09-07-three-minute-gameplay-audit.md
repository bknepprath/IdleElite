# Three-minute gameplay audit

## Setup

Visible production `res://scenes/main.tscn`, raw 1080 × 1920 viewport captures. Separate test profiles with save writes disabled. No Android build or physical-device validation.

The fresh-profile run lasted 185 real seconds without stat, unlock, currency, or material grants. Dismissed the opening dialogue, started Push-Ups, tapped the locked kicking activity, started it after unlocking, and navigated to Fishing. The lock correctly reported `Requires Level 2 Fighting`; training continued after leaving Fighting. No runtime errors in this run.

High-level runs granted levels, action unlocks, onboarding completion, and fishing tools. Berries were collected through gameplay, not granted.

## Bugs fixed

1. Cached fishing cards could intercept location taps with decorative controls. `_enable_interactive_control_tree` changed every ignored control to `MOUSE_FILTER_PASS`, including the full-card border. Input tracing identified that border as the hovered control instead of the location button. Preview construction now records original mouse filters and restoration restores those values. Ordinary cached controls retain their authored behavior. No coordinate-routing fallback was added.
2. Flat activity stat panels did not register their XP controls for berry assignment badges. They now display the existing berry badge, positioned beside the stat panel so it does not obscure XP or timing values.

## Verified gameplay

- Collected at least three berries from Prune Orchard Row, entered berry assignment mode through its button, assigned Gather Fallen Branches, left assignment mode, and started that different activity. One berry was consumed and the base 1 XP reward became 2 XP. The result also reported doubled loot; random material drops varied between runs.
- After the fix, all 23 fishing location buttons started their intended action through native touch input: Shallows, Rocks, Dock Edge, Piling Line, River Bend, Rapids, Drain Gate, Tunnel Pool, Reef Pot, Reef Cage, Ice Hole, Rowboat, Open Water, Night Reef, Pearl Bed, Storm Ripple, Storm Line, Chum Line, Wreck Drop, Abyss, Deep Trench, Starlight, Reflection.
- UI boundary and activity UI boundary contracts passed.
- Native high-level wallet selection passed for hands, net, star rod, boat, and mirror. The upgraded rod replaces earlier rods in the wallet; they are not separate high-level buttons. Net catches accumulated (2/10), boat catches loaded (10/200), and rod/mirror rewards were observed at Dock Edge. Manual net/boat unloading was not covered in this pass.
- Chickens, Giants, and Dragons accepted native start taps. The final level-99 samples awarded 107 XP from Chickens and 1,537 XP from Giants over 12 seconds each. Dragons awarded zero XP over 40 seconds, with knockout/restart behavior observed. The combat audit therefore retains a failing dragon-reward assertion; this is a balance/reward follow-up, not a claim that every gameplay check passed. A short stochastic sample does not establish a broken reward mechanism.

## Suggested improvements

1. Put fishing tool suitability outside the XP value box. `AWFUL TOOL` is clipped to `AWFU` in the Reef capture and replaces useful reward information. Identify the better tool in the same interaction.
2. Keep tired-training status visible when viewing another skill. The fresh run continued training at 20% speed after navigating away, but its on-card status was no longer visible.
3. Preview the berry-adjusted reward when berries are available and assigned. The badge now confirms assignment, but the stat still displays base XP while the completion awards boosted XP.
4. Leave more room above the arena when jumping to Giants. Its upper artwork can touch or disappear behind the fixed skill header at the automatic scroll position.
5. Review dragon kill time and repeated knockouts at level 99 with longer seeded samples. Make the reason for failure and progress toward a kill clearer before changing difficulty or rewards.

## Evidence

Logs: `.codex-tmp/three-minute-audit/fresh.log`, `fixed.log`, and `tools2.log`.

Raw captures: `.codex-tmp/three-minute-audit/high/berries-used.png`, `fishing-reef-cage.png`, `tool-*.png`, and `fight-*.png`.

Repeatable gameplay checks: `scripts/tests/fishing_berries_gameplay_audit.gd` and `scripts/tests/tools_combat_gameplay_audit.gd`.
