# Ham feedback: 6 October 2026

Source: Ham OSRS Discord DMs, 6 October 2026. Scope includes the user's approval to implement hub upgrades.

Art and help presentation were revised on 7 October at the owner's request. See `ham-feedback-art-help-revision.md` for the current compact module help and five-state hub sheets; the full-screen help and two-cell art described below are superseded.

| Feedback | Change |
| --- | --- |
| Combat missions count waves rather than enemies | Each valid enemy kill advances its matching mission once, independently of XP. Medal progress retains its existing XP-based rate. |
| Toolbox stat explanation overlaps the next card | Long presses open a scrollable information panel with 60px titles and 52px body text. |
| Tool and medal effects are unclear | Fishing tool info buttons and tappable medals show numeric effects. |
| Berry help is difficult to use | Berry help uses the same information panel, explaining selection, consumption, XP and loot. Offline completions now award their omitted material loot and secondary combo XP. |
| Hub goals are too far apart and centered on Building | Earlier costs and unlocks; Woodcutting Totem and Fighting Display have their own skill requirements. Pond upgrades require Fishing. Owned levels are preserved. |
| Too many softwood requirements; hardwood lacks a purpose | Second and later wood-funded upgrades use hardwood. Costs and next bonuses remain visible before the skill requirement is met. |
| More multi-skill methods | Repair Small Shack splits its base 6 XP into 5 Building + 1 Woodcutting. Clear Dense Grove splits 29 XP into 24 Woodcutting + 5 Fighting. No extra unlock requirement is added to either existing activity. |
| General crash reports | Fixed two reproduced UI errors: stale freed menu references and hub touch handlers calling a removed host method. The DMs do not establish the cause of every reported crash. |

## Hub balance

Four upgrades per module, each taking 15 seconds. Arrays list tiers 1–4.

| Module | Required skill levels | Costs | Bonus |
| --- | --- | --- | --- |
| Woodcutting Totem | Woodcutting 8, 16, 26, 40 | 25 softwood; 30, 65, 140 hardwood | +10%, +20%, +30%, +40% collected wood |
| Fighting Display | Fighting 6, 14, 24, 38 | 30 softwood; 35, 70, 150 hardwood | +5%, +10%, +15%, +20% Fighting XP |
| Fish Pond | Fishing 5, 12, 22, 36 | 8, 120, 600, 2800 fish | Existing stamina regeneration bonuses |
| Barn | Building 3, 10, 20, 35 | 40 softwood; 45, 90, 180 hardwood | Existing failure-gap reduction |
| Garden | Building 7, 15, 27, 42 | 30 softwood; 35, 70, 140 hardwood; plus 15, 80, 320, 1200 fish | Existing offline cap bonuses |
| Mission Sign | Building 10, 18, 30, 45 | 25 softwood; 30, 60, 120 hardwood | Existing mission bonuses |

The new upgrades use the existing saved hub-module dictionary. Fractional Fighting Display XP is accumulated during an arena run so low-XP enemies still earn the bonus.

## Validation

- `scripts/test-ham-feedback.ps1`: mission kill counts, stale-stage protection, upgrade requirements, spending once, build completion, save normalization, actual wood/XP bonuses, offline berries and combo rewards.
- `scripts/test-ham-feedback.ps1 -VisibleGame`: muted real `scenes/main.tscn`, production controls reached by pointer input, raw 1080 × 1920 captures in `.codex-tmp/ham-feedback-captures`.
- `scripts/test-feedback-balance.ps1`: preserves the earlier stamina-free level-2 Practice Pool and recovery-mission reduction.
- Activity database contract and content audit.
- `scripts/check-project.ps1`: functional checks passed through the activity queue. Its module-list test initially expected the removed inline stat panel; that test now verifies modal content and closing, and passes. The remaining pin appearance, scroll-anchor, and page-interaction checks also pass.
- `scripts/test-skills-page-performance.ps1`: timing thresholds failed for scrolling and swiping. No claim of a clean performance pass; these timing failures are advisory in the default project check.
- `scripts/capture-screen-audit.ps1`: passed; 14 raw 1080 × 1920 captures in `.codex-tmp/ham-screen-audit`. Focused feedback captures also passed, with every PNG checked at 1080 × 1920. No Godot processes remained after validation.

No Android export or device installation was performed. Unspecified crashes still need reproduction details.

## New art

`assets/content/hub/hub-skill-upgrades.png` is a transparent, two-cell sprite sheet generated with the built-in image tool. Original dimensions: 1774 × 887. Fixed cells: 887 × 887. Authored draw boxes: 300 × 300 for the totem and 310 × 310 for the display. These are static hub sprites; no measured alpha bounds control their scale.

Generation prompt:

> Create a transparent PNG sprite sheet for Idle Elite mobile game hub. Exactly two separate sprites, side by side in equal square cells, no overlap. Left: a wooden woodcutting totem, three stacked carved log faces, crossed axes at base, small green leaves. Right: a Fighting trophy display, sturdy low wooden rack with a gold boxing glove trophy at center, a round shield leaning left, simple practice punching bag hanging right. Full objects completely within each half, generous transparent margins, same ground line, no floor or background, no text or numerals. Match hand-drawn fantasy game art: very thick near-black outlines, flat warm earthy tan brown ochre colors, simple chunky toy proportions, restrained flat shading, high readability at small mobile size. Isometric three-quarter view; crisp distinct silhouettes. No photorealism, glow, tiny ornamentation or gradients. Deliver 1536x768 if possible.
