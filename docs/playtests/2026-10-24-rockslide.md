# Clear Rockslide, October 24

## October 25 polish

- Distinct left/right fragment launch velocities and bounce arcs, with ground shadows and landing dust
- Slingshot recoil, brighter projectile trails, separate rock chips and break rings, and signed fading damage numbers
- Volleys reserve in-flight damage so lethal shots spread to surviving fragments
- Four clearance markers below the wave counter; a brief highlight when advancing
- Upgrade controls show current → next damage, shots/second and projectile count, then price; purchased controls briefly brighten and unavailable controls turn gray
- Tap to retry after failure; authored height increased from 840 to 900 to preserve 48px upgrade text without clipping
- Gameplay test adds fragment-trajectory and reserved-volley targeting checks; actual-main capture now also verifies wave advancement

`scripts/test-rockslide.ps1 -VisibleGame` passes after the final layout revision, with both reports containing `failures=[]`. Database contracts, UI-boundary contracts and asset paths also pass. Raw 1080×1920 shot, split and upgraded frames from that run were inspected. No renderer settings or textures changed in this polish pass. The only remaining Godot process is the explicitly requested user playtest.

`scripts/play-level-50.ps1` launches current desktop source with the muted Dummy audio driver, a separate persistent profile under `.codex-tmp/level-50-player`, all five skills at least level 50, and online requests disabled. Existing test progress above level 50 is retained on relaunch. Automatic initial navigation was unreliable, so Fighting was opened through the actual visible window. Computer Use then confirmed the owner actively playing Clear Rockslide in the center desktop column; automation stopped interacting. The launcher must run on the interactive Windows desktop outside the tool sandbox for the user-visible handoff. Raw desktop menu evidence is `outputs/verification/level-50-playtest/desktop.png`. This is local playtesting, not an exported release or phone install.

Worktree: `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`

The owner requested the satisfaction of hill games such as Rumble Beavers. Its [official store description](https://play.google.com/store/apps/details?id=com.nep.tr.hybrid.cg.rock&hl=en) identifies automatic shooting against falling boulders and weapon upgrades. This implementation uses Idle Elite's blue character and wooden slingshot in a separate Fighting activity unlocked at level 12.

## Behavior

Rocks roll downhill from right to left. Each projectile hits a specific live rock and reduces its HP. Large rocks crack, break into two smaller live fragments and release separate chips. A fully cleared group awards the normal effective XP map, mastery and one Sand, then pays the effective stamina cost exactly once. Sand is declared in the activity's `mat_rewards`, so material-source navigation can discover this source. Escaped groups award nothing and remove one of three path-health points. Losing all three stops the activity. Later waves increase rock health and arrival rate.

Power adds projectile damage, Speed increases actual shot cadence and every Volley upgrade adds a real projectile. Purchases cost Scrapwood, Softwood and Wooden Parts respectively, increase quadratically, and cap at six upgrades. Progress is saved separately from old activity IDs; older cloud saves cannot remove permanent upgrades or best/lifetime progress. The runtime belongs to the host rather than the visual card, so scrolling or navigating away does not stop it. Unfinished unpaid groups and projectiles are transient, and no ordinary timed completions are awarded offline.

Existing activities retain the restored portrait cards. The new activity is excluded from old tier/neighbor indexes. No viewport, renderer or Android graphics setting changed. Longer-session progression and economy tuning remains a playtesting task. No release was exported or published and this change is not on the phone yet.

## Validation

- `scripts/test-rockslide.ps1`: gameplay checks cover real HP/splits, exact-once XP/material/stamina accounting, unpaid waits, actual projectiles, upgrade costs/effects/caps, actual save payload, reset, malformed saves, cloud regression protection, three escapes and offline isolation
- Final wrapper run after standard high-quality VRAM compression: `scripts/test-rockslide.ps1 -VisibleGame` returns `rockslide-ok`; logs `.codex-tmp/rockslide_gameplay.log` and `.codex-tmp/rockslide_capture.log` both contain empty failure lists
- `scripts/tests/rockslide_capture.gd`: actual main scene, real activity taps, three upgrade controls and leaving/returning through real navigation; `ROCKSLIDE_CAPTURE failures=[]`
- Gameplay log: `.codex-tmp/rockslide-gameplay.log`, `ROCKSLIDE_GAMEPLAY failures=[]`
- Real-game capture log: `.codex-tmp/rockslide-capture.log`; shots continued while unmounted (`active=true`, 24 shots after leaving versus 12 before)
- `scripts/test-production-paths.ps1`: production accounting and prior medal strategy pass
- `scripts/test-save-normalization.ps1`: `save-normalization-ok`; known shutdown resource warnings remain in this existing test
- Database contracts, structural database audit, UI-boundary contracts and runtime asset paths pass; no missing assets
- `scripts/configure-performance-imports.ps1 -Check` passes after updating only the two new texture imports; pre-import tracked `.import` files were snapshotted and restored with zero unrelated changes
- `scripts/capture-screen-audit.ps1`: fourteen main screens captured successfully under `outputs/verification/rockslide-oct24/main-screens/`

The raw 1080×1920 PNGs in `outputs/verification/rockslide-oct24/` show idle, shot, impact, split, cleared, upgraded, returned and stopped states from the same main-scene run. Inspected impact, split and returned frames after correcting right-edge clearance, hit-number top padding, wave-counter placement and the stamina symbol. Audio previews were muted. No agent-owned Godot process remained after the completed runs.

## Art

Built-in ImageGen produced the two project-bound assets, copied from the native generated outputs without altering them:

- `assets/content/fight/rockslide/slingshot-poses.png`: two 887×887 cells on a shared 1774×887 transparent canvas, drawn in a fixed 285px canonical box and ground anchor
- `assets/content/fight/rockslide/hillside.png`: 1774×887 scene plate
- `assets/content/fight/rockslide/slingshot-icon.tres`: an AtlasTexture referencing the first pose, with no duplicated bitmap
- Existing `assets/content/fight/enemies/giants/giant-boulder-01.png` supplies the rocks

Approved style references were Building's Patch Fence, Fighting's Wheelbarrow and the Hub decor sheet. Production `worker-0.png` supplies character identity only. The character has a smooth featureless blue head and mitten hands, with no individual fingers. Projectiles, chips and reward effects are independent runtime layers. No runtime scale is derived from alpha bounds. The generation contract is in `output/imagegen/rockslide-oct24/asset-contract.txt`; final prompts and provenance are in `output/imagegen/rockslide-oct24/prompts.txt`.
