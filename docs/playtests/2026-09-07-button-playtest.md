# Actual-game button playtest

Tested the current 1080p worktree through native mouse clicks and drags in the visible production main scene. Used the isolated fishing test save, continuing from Fishing level 6; this was not a fresh-start run. Raw viewport capture verified as 1080 x 1920.

## Observed working

- Shallows: switched from Rocks, then stopped on a second click.
- Rocks: started with a net; repeated net cycles awarded fish.
- Equipment wallet: opened from the gauge; selecting net and hands equipped the tool and closed the popup.
- Locked rod: responded to the click. Its feedback defect is described below.
- Active hands button: displayed Bare hands feedback.
- Pier lock: displayed Requires Level 7 Fishing.
- Fighting chain lock: displayed Requires Level 7 Fighting.
- Activity Queue: opened, started fighting from its card, and subsequently moved back to fishing as stamina recovered.
- Adjust Queue and Done: entered and exited selection mode.
- Clear Queue: reachable by vertical scrolling; clicking removed the queue entries.
- Set Queue: reopened selection mode after clearing.
- Settings: stamina decimal and Dark Mode toggles changed state; light mode was restored. Auto Unlock Lockpads was ON.
- Bottom navigation: Settings, Shop, Player Hub, and Skills opened. The achievements button displayed its Total Level 25 requirement.
- Hub building: Barn opened its cost panel; unaffordable Build did not spend resources.
- Horizontal skill swipe: moved from Fishing to Fighting.
- Overview: opened and displayed updated total level and stamina decimals.
- Sort menu: opened and changed Level: Low to Level: High.
- Pinned Activities: opened its empty state.
- Utility row: collapsed and expanded.

## Fixed during this pass

The locked rod message extended past the right edge and drew behind the equipment popup. Reward floats clamped a fixed 280px box even when their labels were wider. The float now sizes its box from the labels' minimum sizes before clamping. Locked equipment feedback is parented to the wallet popup when its target belongs to that popup, placing it on the same canvas layer.

Verified by clicking the locked rod again in the restarted real game. The exact inspected raw capture is `.codex-tmp/input-fix-validation/button-playtest-locked-tool-final.png` (1080 x 1920). No SCRIPT ERROR or ERROR entries were found in the final live-run log. The test game processes are no longer running; the user's Project Manager was left alone.

## Coverage limits and follow-up

- The Shallows medal accepted a press visually, but the sampled frames did not establish a mastery ceremony result. Do not count this as a verified complete interaction.
- Did not purchase late-game equipment, unlock every fishing area, test every settings toggle, complete a new queue selection after clearing, or exercise every activity card.
- Did not send chat, open Contact the dev, submit a rating, perform a hard reset, or validate real ad delivery.
- Desktop mouse testing does not establish physical-phone touch or Android rendering acceptance.
- After changing sort order, confirm whether retaining locked higher-level cards above unlocked activities is the desired landing behavior.
