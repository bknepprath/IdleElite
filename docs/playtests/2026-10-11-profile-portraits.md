# Profile portrait refresh

Revision 1 was rejected by Brian for thin outlines and excess detail. Revision 2 replaces all five generated images with simplified forms and heavier black contours. The updated PNGs are 256 × 256 RGBA and total 266,431 bytes. The complete authored square is resized; no per-image alpha-bound scaling is used.

| ID | Runtime asset | Effect |
| ---: | --- | --- |
| 0 | `assets/content/ui/profile-portraits/shark-bucket.png` | Replaces the generic starter for everyone using it |
| 18 | `assets/content/ui/profile-portraits/brick-helmet-builder.png` | Replaces the scroll-obscured adventurer for everyone using it |
| 20 | `assets/content/ui/profile-portraits/cookie-jar-thief.png` | Added |
| 21 | `assets/content/ui/profile-portraits/wheelbarrow-champion.png` | Added |
| 22 | `assets/content/ui/profile-portraits/shrub-sunglasses.png` | Added |

The five revised portraits appear first in the picker. Other existing IDs are unchanged. Profile, chat, and leaderboard renderers use the shared portrait resolver. Picker artwork now has a fixed inset to prevent colored sheet corners from extending outside the rounded border.

## Validation

- `node scripts/tests/profile_portraits.test.cjs`: passes; all 23 IDs accepted by all four local Firebase avatar rule branches, out-of-range IDs rejected, five RGBA assets validated.
- `scripts/update-firebase-leaderboard-rules.ps1 -Check`: passes; generator and local rules agree.
- `node scripts/tests/leaderboard_rule_leaves.test.cjs`: passes, eight existing score-safety cases.
- Muted visible real-game tests load `res://scenes/main.tscn` through `run-godot-safe.ps1 --visible-game`. Desktop reaches Chat from the bottom ribbon; mobile opens the actual chat strip. Both click the profile button and avatar, then select every revised portrait. Revision 2 logs report `PROFILE_PORTRAITS failures=[]`.
- Raw viewport captures: `.codex-tmp/profile-portraits-v070/mobile-v2.png` at 1080 × 1920 and `desktop-v2.png` at 1920 × 1080. No cropping, scaling, or compositing is used for the proof screenshots.
- Test audio is muted before scene creation and uses the Dummy driver. Online requests and player-save writes are disabled in the fixture; the offline account notice in screenshots is fixture state.
- Headless imports changed no previously clean tracked `.import` files. Agent-owned Godot processes were checked after each run.

## Remaining release work

Firebase rules for IDs 20–22 are updated locally, not deployed. Verify online profile save, chat, and leaderboard round trips against the deployed rules before release. No release package or release candidate was produced. Physical Android device validation has not been performed for these assets.

Dual training remains unimplemented. The clarified requirements, proposed five-resource workshop, runtime audit, and required tests are in `docs/dual-training-v070.md`.

Generation used built-in `image_gen`, one asset per call, with the approved shop and wheelbarrow references. Prompts and source filename mappings are in `docs/art/profile-portraits-v070/prompts-v2.txt`. Original revision 2 masters are retained in `.codex-tmp/profile-portraits-v070/masters-v2`.
