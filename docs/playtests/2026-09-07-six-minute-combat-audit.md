# Fresh-profile and animated-combat audit, 2026-09-07

## Coverage

Fresh profile: 12:18:58 through at least 12:25:06 local time (368 seconds). No stat grants or onboarding skips. Started Push-Ups, changed to Practice Kicking, tested a locked activity, visited the skill overview, trained Thieving and Building, gathered branches, and lit the automatically unlocked firepit. Save data was isolated from the player profile.

Separate level-99 profiles: real production-scene combat against chickens, goblins, cave trolls, giants, vampires, and dragons. Chickens, giants, and dragons were sampled for 60 seconds each, then repeated after fixes. Additional enemies received 30-second samples. Checked native touch starts, waves, damage, XP, knockout/restart, navigation away, and return behavior. Captures are raw 1080x1920 game viewport PNGs in `.codex-tmp/six-minute-audit`.

## Fixes

- Combat statistics used a rectangular layout over a triangular backing. Text now fits the exposed bottom-left red corner. The longest damage line occupies the widest, bottom row.
- Giant animation content-bound reads called AtlasTexture.get_image on compressed textures, which attempted an unsupported compressed blit before decompression. The source atlas is now decompressed before reading its region. Authored sprite scales are unchanged.
- Direct navigation rebuilt the active combat control, stopping rewards while the action still appeared to run. The active battle is retained during page replacement, reattached when revisited, and disposed when a different action replaces it. Hidden-page processing remains active for the running fight.

## Recommendations

1. Keep skill-switch controls in a stable location. Material panels appearing below activities moved the navigation targets out of view during the fresh run.
2. Keep the tired-training explanation visible while stamina is empty. The brief floating message is easy to miss, leaving a much slower progress bar without a persistent explanation.
3. Clarify the difference between the header stamina gauge and the combat HP bar. Knockout recovery, stamina costs, and combat HP currently require inference.
4. Show combat activity identity while fighting and explain what the wave meter measures. The arena replaces the activity title, and elapsed-wave progress can be mistaken for remaining enemies.
5. Review late-game XP balance with repeated seeded runs. One 30-second level-99 cave-troll sample awarded 133,333 XP, while the initial 60-second giant and dragon samples awarded 21,425 and 4,812 respectively. These are observations, not stable rate estimates.
6. Review large-enemy movement at the arena edges. Giant defeat motion can overlap the next module, and dragon flight can be obscured by the fixed header. Avoid scaling individual animation frames to address this.
7. Reduce repeated displays of the same Scrapwood balance between the branch activity and firepit. The duplicate dependency panels consume considerable vertical space.

## Limits

Desktop playtesting does not clear physical Android rendering. No release artifact was built or uploaded. Shutdown reports still include texture/ObjectDB resource leaks; these remain a release-audit item. This was targeted gameplay coverage, not an exhaustive verification of every late-game activity or a full balance certification.

Final validation: combat_navigation_regression.gd passed native start, XP while away, same-stage reuse on return, exactly one active simulation, native replacement by Woodcutting, and no further combat XP after replacement. The six-enemy gameplay runs completed with reward progression. UI boundary, activity UI boundary, and crash audit contracts passed. No compressed-image blit errors occurred in the fixed runs. All test-owned Godot processes exited; the existing user Project Manager was left alone.


The approved follow-up fixes and validation are recorded in [Audit fixes](2026-09-07-audit-fixes.md). The recommendations and shutdown leaks above have been addressed in that follow-up.
