# Slingshot playtest corrections

Removed the XP range, repeating tutorial arrow, gold timing cue and tap-release bonus. Starting the card now runs automatic shots. Removed all distance readouts above the shooter; the grounded flag is the only personal-best label. Landing retains the actual XP flyer.

Changed the source database first: new-shot reward is 2 base XP plus 0.08 per meter, previously 5 plus 0.25. Representative unboosted midpoint rolls at levels 6/25/50/99 changed from 8/13/22/44 to 3/5/8/15. Duration, level-based range, dispersion, stamina base, stored records and historical paid airborne XP remain intact.

Stamina already paid at release. Tests confirm 20 launches make 20 exact effective-cost payments, drawing pays nothing, duplicate launch calls cannot charge again, exhaustion prevents a free shot and paid flight survives reload/activity switches without another charge. Regeneration can offset a payment in the same frame. A real Mission Board discount also permits an actual fractional debit without a change to the integer gauge. A brief stamina-symbol/cost flyer now makes each release payment visible.

New records move continuously toward their landing and grow from a planted pole base. The 0.65-second pop overshoots to 1.18 and settles to 1. No frame-dependent actor scale is used. Existing records load at settled size. Flag motion is local presentation and never changes saved record distance.

The shared header helper uses authored static icon source rectangles, matching numeral height and preserving a four-pixel icon/value gap. This applies to Slingshot, Rockslide, Grove and factory XP/time headers. Converter XP symbols can omit their old shader; their resize handler now safely allows that state. Ordinary activity stat chips are unchanged.

Validation passed:

- Database contracts and activity audit, with existing progression warnings and no missing assets
- slingshot_range_rework.gd: release accounting, repeated calls, exact-once landing, regen, real discounted cost, exhaustion, legacy/modern paid-shot restoration and reward comparisons
- groves_and_range.gd: existing arena/save and paid-flight regressions
- Real main scene slingshot_range_capture.gd: actual navigation/start/touch, no timing bonus/arrow, one header stat, all eight actor poses, landing XP once, continuous flag travel, overshoot/settle and all four header types
- Eleven raw 1080x1920 frames inspected under outputs/verification/slingshot-feedback-oct25; before/transition/settled flag frames came from one real-game run
- No script/parse errors in the final visible-run log; the environment emitted its existing root-certificate warning
- No agent-owned Godot process remained after verification

Tests used isolated user storage, disabled online requests/save writes and muted audio. An initial visible test was blocked by the real desktop recovery-save state; rerunning with the wrapper's isolated user-data option reached the production controls. No player save was changed. No renderer/stretch setting, Android export/install or external publication was performed for this revision.

Fight the Current was inspected, not redesigned: each success increments permanent waterwheel clearance, capped at eight. Eight clearance completions let Building reserve the wheel construction materials and perform eight repair completions. The built wheel supports up to twelve prepaid sequential crafting jobs, including offline execution, without background XP. The counter is not a temporary combat charge. Further Current completions after eight continue normal XP without increasing clearance.
