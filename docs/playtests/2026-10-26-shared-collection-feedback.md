# Shared collection feedback

Candy's missing drop was caused by an early return requiring ordinary material rewards before the candy-specific animation could be appended. The holder existed and the Candy balance increased, but the visual path never ran for a candy-only completion.

Activity rewards now publish one shared item-collected receipt after the inventory is credited. Ordinary materials use collect_amount; the seasonal wallet reports its actual credited delta through the same signal. The collection surface batches receipts by source action and animates each positive item to its matching visible holder. Animation code no longer infers a Candy reward or checks activity names. New data-defined materials receive both their holder and their reward notification without a renderer exception.

Each sprite pops out of the action artwork, follows a curved path and drops into its current holder position. The endpoint follows layout movement. It fades after arrival, and the holder icon pulses on arrival. Shared reward cleanup removes in-flight sprites when leaving the screen; a destroyed/hidden holder cancels delivery. These visuals do not grant inventory. Per-item burst counts preserve berry double harvests without accidentally doubling a separate Candy receipt.

Zero rolls, capped Candy, inactive events, inventory restore/set/spend and offline rewards do not emit live collection feedback. Actual offline balances still advance. Existing factory conversion/output-delivery events and grove per-log harvest visuals remain separate from ordinary holder routing; production accounting and live factory output were checked for duplicate or unpaid rewards.

Validation passed:

- collection_rewards.gd: all fifteen standard-holder activities, actual credited quantities, candy-only rewards, capped/ended/offline Candy, offline material grants, zero/invalid rewards, non-collection balance changes, a newly registered material and mixed per-item harvest counts
- collection_rewards_capture.gd: all fifteen standard-holder activities reached through the real main scene and actual card input, holder opening, real completion-driven item receipts, rising/falling paths, matching targets, actual arrival, cleanup and no extra inventory from animation
- production_paths.gd: production reservation/output/save regressions
- factory_inventory_capture.gd: live Melt Sand input/output holders, output delivery, exact quantities, connector continuity and no unpaid extra output

The collection report records all fifteen actions and their item IDs in outputs/verification/collection-rewards-oct26/result.json. Before, pop, travel, fall and settled images were captured directly at 1080x1920 from the same real-game run. All seventy-five PNGs retain those raw dimensions. Separate factory evidence is under outputs/verification/collection-factory-audit-oct26. Final logs have no script/parse errors; the environment retains its existing root-certificate warning.

The user reported audible testing. The initial master mute could be overwritten by AudioDirector startup. The safe launcher now selects the Dummy audio driver for visible previews unless explicitly given --preview-audio following a human request for sound. The shared real-main capture harness also reapplies music, SFX and master mute after startup. The running test process command line was independently inspected and confirmed --audio-driver Dummy, and runtime tests confirmed all mute states after loading. Delivered exports keep their audio; player settings are not modified by these isolated tests.

No Android export, phone update or external publication was performed. Tests used isolated user storage with save writes and online requests disabled. No agent-owned Godot process remained after verification.
