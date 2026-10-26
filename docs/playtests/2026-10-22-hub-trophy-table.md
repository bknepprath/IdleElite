# Player hub trophy table, October 22, 2026

Corrected the four stolen trophies displayed on the actual table in the Player Hub. This replaces the withdrawn heist-card verification; the unrelated heist layout was restored exactly to its prior contents.

Changed `scripts/ui/hub_surface.gd`: each trophy uses an authored square draw box and a source bottom anchor. Following Brian's spoon correction after the phone preview, the spoon's visible base lands at y=83 within the table button; the other trophies remain at y=75. Both anchors are in the lower third of the illustrated tabletop. Transparent source margins affect positioning only. Display scale is fixed explicitly per trophy, independent of measured bounds.

| Hub trophy | Authored square | Visible size at 1080px viewport |
| --- | --- | --- |
| Spoon | 210px | 102 x 107px |
| Jewel | 280px | 103 x 121px |
| Idol | 300px | 96 x 135px |
| Crown | 250px | 111 x 127px |

The table's visible width is approximately 139px. The trophies occupy 69–80% of that width. The table image, saved positions, trophy acquisition and bonuses are unchanged. The portrait color correction from the previous pass remains in place.

## Verification

`scripts/tests/hub_trophy_table_capture.gd` loads the production main scene with isolated test data, seeds each acquired-trophy tier, and enters the Player Hub through the actual bottom navigation. It reads the real table and trophy controls in the hub hierarchy, checks their visible source bounds, captures the hub, taps the displayed trophy, verifies that the trophy details open and dismisses them.

The spoon base now measures y=603 on screen, 8px lower than the first pass, with an 8.7% smaller authored draw box. The other three bases remain y=595. All are inside the tabletop's lower-third interval y=589.31–603.50. All four size and touch checks passed again: `hub-trophy-table failures=[]`. The source atlas is decompressed before reading its alpha bounds; no source pixels or scales are modified by this check.

Inspected all four raw 1080x1920 screenshots below. No crop, resize, compositing, isolated control or substitute scene was used. The required fourteen-screen audit completed. Activity UI boundaries, UI boundaries, generated-file hygiene, native-1080 contracts and test-harness contracts passed. Preview audio used Dummy; ordinary save writes and online requests were disabled. No release was packaged.

Raw capture dimensions and SHA-256 values: `outputs/verification/hub-trophy-table/capture-manifest.json`.

The table is on the upper-right side of these hub screenshots.

![Hub table: complimentary spoon](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/hub-trophy-table/complimentary_spoon.png>)

![Hub table: crown jewel replica replica](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/hub-trophy-table/crown_jewel_replica_replica.png>)

![Hub table: bad decisions idol](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/hub-trophy-table/bad_decisions_idol.png>)

![Hub table: borrowed empire crown](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/hub-trophy-table/borrowed_empire_crown.png>)


