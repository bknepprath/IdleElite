# Fresh-save playtest: 6 September 2026

- Duration: 11 minutes 16 seconds, from 22:43:49 to 22:55:05 America/Chicago (03:43:49 to 03:55:05 UTC, 7 September).
- Project: `.codex-tmp/worktrees/idle-elite-1080p`, actual `res://scenes/main.tscn`, 1080x1920 viewport displayed at 540x960.
- Input: desktop mouse clicks, wheel scrolling, and drag swipes through the actual game UI.
- New isolated save; no progression injection, time acceleration, or god mode. The capture harness only observes input and saves raw viewport images.
- Before the run, Contact the Dev was moved below the settings toggles with a 64px gap, away from Hard Reset and bottom navigation. Its raw 1080x1920 screenshot was visually checked.
- Final saved levels: Fighting 4, Fishing 3, Woodcutting 3, Building 2, Thieving 1. Shop unlocked. Hub remained locked.

## Highest-priority changes

### 1. Repair the Fishing drawer in the skills overview

Open the colored-dots skills overview while Shallows is running. The overview displayed `Total Lv 5` even while the visible rows showed Fighting 3, Thieving 1, Building 2, and Woodcutting 2, plus Fishing below the fold. The number remained unchanged over multiple observations.

Post-run log inspection found repeated errors from `navigation_shell.gd:3479`: `_sync_skill_menu_active_drawer` calls nonexistent `host._build_fishing_area_module`. The calls originate during `_sync_skill_menu_page` / `_update_ui`. This is a confirmed runtime error; it may also interrupt the total-level refresh. Repair the call and then verify both the active Fishing drawer and total-level label.

Evidence: `.codex-tmp/input-fix-validation/playtest-total-level-mismatch.png` and the fresh-save `logs/godot.log` listed below.

### 2. Verify and repair automatic queue handoff

Reproduction from this run:

1. Open Activity Queue, press Set Queue.
2. Select Practice Kicking, then Shallows.
3. Return using the queue icon. Both entries appear in order.
4. Click Practice Kicking in the queue with about 23 stamina.
5. Wait for Fighting stamina to reach zero.

Fighting continued at zero stamina for over 30 seconds while Shallows remained idle. Starting Shallows directly in the queue worked immediately. The queue instructions say the next activity starts when stamina is low, so the observed behavior contradicts the explanation. Investigate whether ordinary activity-card clicks start training without activating the queue. This is an observed symptom, not a confirmed code-level diagnosis.

Evidence: `.codex-tmp/input-fix-validation/playtest-queue-no-handoff.png`. Saved queue entries are `action:fight:kick-mud-off-boot` and `fishing_area:fishing:area-beach-0`.

### 3. Align multi-unlock page jumps with the full latest activity

At Fighting level 3, navigate from Fishing with the right page button. The incoming page positioned Wrestle Stuck Gate Latch partly above the content viewport: its name, XP row, and upper artwork were hidden beneath the fixed header. The next locked activity and navigation arrows were fully visible instead. Scrolling upward recovered the card.

Align the latest unlocked card's top beneath the fixed header rather than jumping to the content bottom. Preserve the working top-of-page behavior when only one activity is unlocked.

Evidence: `.codex-tmp/input-fix-validation/playtest-clipped-latest-activity.png`. The same capture confirms the locked Fighting activity correctly shows `Requires Level 4 Fighting`.

## Other possible changes

### 4. Keep queue management buttons above the utility row

With the utility row expanded, Clear Queue sits behind its buttons. Collapsing the row reveals the full Clear Queue button. Give the queue content sufficient bottom clearance. Add an obvious way to finish selection; the `QUEUE SELECTION MODE` banner looks actionable but clicking it did not exit selection. Returning through the queue icon works, but is not explained.

### 5. Reduce Firepit layout movement and duplicate resource displays

Train Gather Fallen Branches to Woodcutting 2, then tap the Firepit. Starting the fire inserted a second Scrapwood panel with the same quantity as the existing panel and pushed the Firepit farther down. The unlit Firepit says `Fire is out` but does not clearly indicate the ignition action. Keep the interaction in a stable position, consider sharing the resource display, and make ignition discoverable. Once lit, the stamina regeneration benefit and remaining duration are clear.

Evidence: `.codex-tmp/input-fix-validation/playtest-duplicate-scrapwood.png`.

### 6. Connect first stamina depletion to Fishing and the queue

The first Fighting stamina depletion occurs early. Tapping the empty gauge shows `need fish!`, but there is no direct route from that message to Fishing. Fishing's info button explains the mechanic well once found. The queue is also useful at this stage but is hidden behind the small side arrow and an unlabeled icon. Surface the relevant next action at first depletion without adding permanent explanatory text everywhere.

## What worked

- Auto Unlock was ON and eligible activities unlocked during play.
- Shallows started on its first tap, worked after navigation, could be selected into the queue, and could be started directly from the queue.
- Pages with one unlocked activity opened at the top.
- The shorter XP bar and gauge spacing remained comfortable in Fishing, Fighting, Building, and Woodcutting.
- Hub's locked message clearly stated its Building level requirement.
- The locked Fighting activity showed the requested level-and-skill floating text.
- Firepit ignition completed and displayed its regeneration benefit.
- Contact the Dev is separated from both the close/navigation control and Hard Reset.

## Artifacts

All paths below are relative to the 1080p worktree.

- Fresh save: `.codex-tmp/eleven-minute-playtest/fresh-20260906-224314/Godot/app_userdata/Idle Elite/idle_elite_save.json`
- Runtime log: `.codex-tmp/eleven-minute-playtest/fresh-20260906-224314/Godot/app_userdata/Idle Elite/logs/godot.log`
- Settings proof: `.codex-tmp/input-fix-validation/contact-dev-raised.png`
- Additional evidence: `.codex-tmp/input-fix-validation/playtest-*.png`

No external Contact the Dev, Play Store rating, or advertising action was triggered. No gameplay changes beyond the requested Settings placement were made in this pass. The test game was closed afterward; the user's Godot Project Manager was left running.
