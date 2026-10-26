# Honey bottling

Loot Beehive uses its ordinary action card again, with the existing art, rewards, mastery frame and progress rail. Before owning bottles, activating it opens one Honey holder. The first acquired empty or filled bottle reveals the bottle input and both output holders. Bottle and Use are independent saved toggles; the controls stay accessible when inactive.

One honey hand plus one empty bottle makes one ten-second Bottled Honey. With bottling off or no empties, the same harvest remains a honey hand. The lower-left portrait badge reflects the next output. Both actual credits use the shared collection receipt and falling-item animation. Use off preserves unopened bottles; Use on opens a bottle as needed during another running activity and returns its empty bottle. Raw honey retains its existing automatic stamina behavior.

Production save version 2 preserves old activated doses and each old full bottle's sixty-second value. Old partially filled jars return their stored hands and paid empty once. The original save keys remain readable.

Validation:
- `honey_bottling.gd`: conversion, empty supply, both toggles, discovery persistence, cross-skill use, offline use, legacy sealed/partial/active values and repeated restoration
- `production_paths.gd`: all production accounting and existing queue/equipment behavior
- `collection_rewards.gd`: shared collection receipts across sixteen holder activities
- Database contracts and audit pass, with zero missing assets
- `honey_bottling_capture.gd`: real main scene, actual card/button taps, raw and bottled drops, depleted-bottle fallback, and subsequent Building activity consuming exactly one bottle
- Final evidence: `outputs/verification/honey-bottling-oct26/verified/result.json`, no failures
- All ten proof frames are raw 1080 by 1920 captures; no editor or isolated control renders
- Preview muted through Dummy audio; no agent-owned Godot process left running

The first visual pass exposed a hidden Use button behind the utility row. The final layout fits above that row, shows full inventory names, retains the ordinary medal position and has readable black text in both toggle states.

Local source changes only. No phone installation, export or publication.
