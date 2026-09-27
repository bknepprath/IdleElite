# Audit fixes, 2026-09-07

## Changes

- Skill-switch buttons now sit outside the activity scroll container, above the utility row. The scroll limit reserves their height. Their backing blocks taps through to covered activities.
- Ordinary training shows `Tired: 20% speed` persistently when stamina cannot cover its cost. Recovery and monster arenas are excluded.
- Fighting has a header info button explaining stamina, separate arena HP, punch and knockout costs, automatic recovery, and the time-based wave meter.
- Active arenas show shortened names such as Dragons angled along the top-right edge. Wave meters identify time, and the knockout overlay shows the restart countdown. Combat stats remain in the bottom-left dark red corner, including during knockouts; the fixed 32px font is larger and sits higher than the previous auto-fitted text.
- Enemy sprites use their rotated visible bounds for position limits. Authored draw scales are unchanged. Health bars follow visible sprite bounds and remain inside the module.
- Firepit suppresses its duplicate Scrapwood dependency panel when the running gatherer's output panel already shows that balance on Woodcutting. The standalone dependency panel remains available elsewhere.
- Early focus notifications no longer create input/audio children while the scene is being attached. This prevents detached audio players and repeated playback errors during startup.
- Hidden combat artwork and unused stat labels now have scene owners. Fishing's hidden status labels also have owners. Parked lazy cards remain under a hidden cache node instead of becoming orphaned controls.
- A routine Fighting-stat refresh no longer raises zero HP to one before knockout handling. The recovery regression verifies zero HP survives refresh, enters knockout, and restarts with restored HP.
- Swipe combat previews initialize the correct action and remain inactive until promoted. Initial combat activation also checks the action ID.

## Combat rewards

The database remains the source of truth. The large werewolf and cave-troll clear rewards caused extreme XP rates once those encounters became easy. Rewards now form an increasing level-99 progression across the nine encounters. Starting chicken, goblin, and human-swarm rewards also prevent early successful kills from rounding to zero XP.

The audit uses 16 fixed seeds per encounter and level, with three simulated minutes per seed. It checks unlock, unlock + 8, midpoint, and level 99, deduplicated and sorted: 544 samples across 34 encounter/level combinations. Checks require positive XP, non-decreasing XP as Fighting improves, and level-99 reward bands. Earlier near-par snapshot targets have been replaced because the rewards intentionally changed.

| Encounter | Previous level-99 XP/hour | Revised level-99 XP/hour |
| --- | ---: | ---: |
| Chickens | 164,368 | 164,368 |
| Goblins | 720,235 | 240,008 |
| R.O.U.S.es | 479,876 | 299,965 |
| Guys | 341,473 | 341,473 |
| Werewolves | 13,596,671 | 419,980 |
| Cave trolls | 14,249,990 | 569,990 |
| Giants | 1,294,465 | 650,214 |
| Vampires | 729,570 | 729,570 |
| Dragons | 409,050 | 903,125 |

These are seeded simulator rates, not a promise of identical short-session results. Existing XP and save identifiers are preserved. Lower-level rewards also change with the revised reward curve.

## Verification

- Real main-scene gameplay at a raw 1080x1920 viewport; native touch starts and page switches.
- Combat navigation regression: XP continues away from Fighting, the same stage resumes, exactly one battle is active, and replacing it with Woodcutting stops combat XP.
- UI, activity UI, crash audit, and activity database contracts passed.
- Knockout regression passed: zero HP survives stat refresh, recovery starts, HP restores, and combat restarts automatically. Early focus loss creates no orphan input/audio controls.
- Gameplay and native navigation checks passed. Shutdown reported no orphan controls or leaked resources.
- All 544 seeded balance samples passed; the isolated safe-wrapper run exited successfully.
- Raw screenshots and logs: `.codex-tmp/audit-fixes/`.

Desktop verification does not replace physical Samsung rendering validation. No Android release was exported or published.

Final visible validation: final-layout.log exited 0 with AUDIT_FIXES failures=[] and no orphan objects after shutdown. All 21 proof PNGs verified at 1080x1920. Test-owned Godot processes exited; the user's Project Manager was left running.
