# Rockslide idle recovery and resource names

Cost-resource rows identify Scrapwood, Softwood and Wooden Parts from the material catalog. The Sand reward also shows its name when tapped. These independent targets work with touch/mouse and while the corresponding upgrade is unaffordable. They consume the tap without buying an upgrade or toggling the activity. Names appear for 1.8 seconds in 52px outlined text above the controls. Upgrade names/current values remain purchase targets.

Three escaped groups now knock out the worker while keeping Rockslide active. The source database sets a five-second recovery. Unpaid rocks and projectiles are cleared; shooting, spawning and rewards pause. The worker plays the existing six knockout poses, stays down with a countdown, then reverses the poses to stand up and automatically restarts at wave one with three integrity. Upgrades, earned XP/materials, lifetime clears and best wave are retained. Explicitly stopping cancels recovery. Leaving the screen does not interrupt it.

Knockout art uses one authored 640px canvas, (320,540) sole anchor and fixed 280px draw box. No per-frame scale from alpha bounds, new generated art, display setting changes or phone installation.

Save version 2 adds the bounded remaining knockout timer. Earlier saves remain readable. Loading during recovery retains the timer and cannot replay discarded unpaid rocks. Offline time still grants no generic Rockslide completions.

## Validation

- Source database contracts and structural audit passed
- `scripts/tests/rockslide_gameplay.gd`: `ROCKSLIDE_GAMEPLAY failures=[]`, including no rewards while down, repeated knockouts, saved recovery, automatic wave-one restart, retained progression and explicit stop
- `scripts/tests/rockslide_idle_capture.gd`: `ROCKSLIDE_IDLE failures=[]`, including actual touch/mouse resource taps, unaffordable resource inspection, unchanged upgrades/action state, purchase input, complete animation/countdown/restart and recovery while unmounted
- Existing `scripts/tests/rockslide_capture.gd`: `ROCKSLIDE_CAPTURE failures=[]`, covering real shots, splitting, paid rewards, all three upgrade purchases, later waves and away/return navigation; shots continued offscreen from 27 to 39
- Raw production-scene 1080x1920 evidence: `outputs/verification/rockslide-idle-oct25/final/`, showing resource names, wave three before knockout, fall start/transition, settled knockout, standing back up and automatic wave one
- Required Fighting screen audit passed `screen-audit-ok`, with raw evidence under `outputs/verification/rockslide-idle-oct25/screen-audit/`

The first visual pass exposed a resource label overlapping button titles. Its final placement clears all three buttons and the wave label. All previews were muted and the phone remains unchanged.
