# Page swipe latency audit

Reproduced incoming-page delays through real touch events in the production main scene at 1080 by 1920, with Dummy audio and isolated test storage. Fourteen measured swipes cover both directions, repeated navigation, wraparound, a cold neighbor invalidation and a return swipe. Measurements exclude screenshot readback and PNG saving.

| Metric | Before | After |
|---|---:|---:|
| Median release-to-settled page | 684.8 ms | 117.5 ms |
| Maximum release-to-settled page | 1103.1 ms | 141.7 ms |
| Median first visible incoming cards from gesture start | 802.6 ms | 303.5 ms |
| Maximum sampled frame interval | 250.2 ms | 77.4 ms |

The shared lazy-mount flag stalled neighbor preparation on the builder's own previous frame. Preparation also built both skeletons before finishing either side, paused during horizontal motion and could continue the wrong side through a reversal. The update distinguishes its own work from current-page work, prioritizes the intended side, batches twelve cheap placeholder slots per frame, continues bounded work during drags/settles and retires an unfinished unseen wrong-side render at its safe yield boundary. Only the incoming side is completed synchronously at drag recognition. No renderer, viewport, gesture threshold, save or progression changes.

Visual review also found tree-arena button labels/faces waiting for active processing to receive their geometry. Setup/resize/refresh now lays out the controls explicitly, including disabled neighboring pages. Final raw before/during/settled frames show the full incoming page and correctly positioned button faces. Page identity/scroll preservation, first swipes, five fresh-save swipes and interrupted-settle/no-snapback regressions passed. Existing regression scripts emit shutdown resource-leak warnings; no runtime script errors or incorrect landings were observed. Every command finished with no agent-owned Godot process remaining.

Evidence:
- `outputs/verification/swipe-latency-oct26/baseline/result.json`
- `outputs/verification/swipe-latency-oct26/verified/result.json`
- `outputs/verification/swipe-latency-oct26/final-visual/result.json` and nine raw 1080 by 1920 PNGs
- `.codex-tmp/skill-swipe-adjacent-pages-final-oct26.log`, `skill-swipe-first-swipe-final-oct26.log`, `skill-swipe-fresh-save-final-oct26.log`, `skill-swipe-release-no-snapback-final-oct26.log`

These are desktop measurements of the portrait mobile layout. No phone installation, physical-phone performance claim or release export was made.
