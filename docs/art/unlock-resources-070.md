# Unlock resource artwork and behavior

Updated 2026-10-14. Supersedes the earlier numeric badges and code-drawn damage effects.

- Portraits show resource icons without +1/+2 labels. Blockers show their icon and curved bar without fractions. One tap on a blocker says what it needs; a second tap within half a second goes to the best unlocked producer of an item. A seal that any activity of a skill fills has no one producer and goes nowhere (October 16).
- Resources follow activity families across skills. Coins come from money-related activities, Rivets from fastening and metal-related activities, and Resin replaces the old Trail marks sign. The serialized `trail-marks` ID remains stable. Plans and Lures remain available; Wisdom is separate. The red fist seal and the purple key seal keep their ids (`grit`, `clues`) and are shown to the player under their skill's name, Fighting and Thieving (October 16). They are shown on the locked frame that asks for them and not on the activities that fill them: every activity of the skill does (October 17).
- Successful activities award fixed units to the earliest unfinished revealed compatible blocker, carrying surplus forward. No inventory is spent. Random drops remain a possible balance experiment, not implemented behavior.
- Project material progresses through timber, stone, iron, bronze, silver, gold, titanium, platinum and obsidian. Materials share assets across activities.
- All cover, damage, holder, resource and debris art is generated with the built-in ImageGen tool. Code only selects frames, moves sprites and fades them. The rejected procedural zigzags and polygon chips have been removed.

## Asset contract

Style anchor: `assets/content/build/actions/02-patch-fence-with-confidence.png`; the approved shop icon also informed the original holders. Existing covers were supplied as subject references for damage generation.

Timber and stone use the earlier broad ImageGen sheets (`project-timber-states.png`, `project-stone-states.png`), with three authored 768x230 atlas cells. The other seven materials retain four authored 418x220 damage frames. All states of a material share one canvas and centered anchor. Covers are sized from the activity width plus 48 design pixels, preserving aspect ratio; they are not shrunk to fit the card height. Metal and obsidian rows reserve 96 extra design pixels to prevent overlap with neighbors. Fixed row and column regions were extracted and positioned on the canonical canvas without per-frame scaling or redrawing. Neighbor-cell spill was removed by correcting extraction boundaries. Debris uses fixed 96x96 canvases, with six short-lived sprites per transition. Hidden or completed effects free their sprites and stop processing after at most 0.7 seconds. No detached debris is baked into cover frames.

Runtime files: `assets/content/ui/project-damage-*.png`, `project-chip-*.png`, `unlock-holder-*.png`, `unlock-resin.png`, `unlock-rivets.png`, `unlock-coins.png` and existing resource icons. Original generated masters remain outside game exports.

Exact prompts: [materials and resources](unlock-material-prompts-070.json), [damage and debris](unlock-damage-imagegen-prompts.json).

Damage source masters under `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/`:

- Timber/stone/iron: `exec-55959ad3-3d45-4b98-ada8-6e0d46db84e6.png`
- Bronze/silver/gold: `exec-e1ee8d62-3d7c-4ec7-8fca-0aa1f65c8437.png`
- Titanium/platinum/obsidian: `exec-848add3e-992d-4771-b57d-8b848489b54d.png`
- Debris: `exec-45268b0c-fbe4-4c77-a3c8-617c824f13d0.png`

## Compatibility and validation

Project IDs, step IDs and accumulated work remain stable. Active and offline completion share the same allocation path. Production-scene validation is in `scripts/tests/project_resources.gd`; historical prototype/barrier tests delegate to it. Captures use the actual main scene, isolated test data, disabled online/save writes and muted audio. This is prototype validation, not physical Samsung or release acceptance.

The 36 damage frames and nine debris sprites total 2,970,098 PNG bytes before export compression. These are shared material assets, not unique art per activity.

Unlock-resource badges occupy the portrait top-right. Stored inventory drops retain bottom-left. Unlock resources appear only while a revealed progression blocker still needs that resource, independent of which skill is selected or which cards are currently mounted. Filling that resource requirement hides all matching badges, even if another resource or level gate remains. New revealed demand restores the badges. Hidden later projects do not receive surplus, and unused units are not banked. Allocation takes a revealed-target snapshot for each completion/batch so visibility changes during an award cannot grant resources to an unseen project. Availability refreshes are coalesced after progression/render changes; badges listen to one shared signal rather than polling every frame.

Corner badge revision: unlock-resource icons use the existing 86x86 badge size and 30px outward overlap, mirrored onto the top-right corner. Demand changes animate opacity with a 0.28-second cubic ease; reversing demand cancels the previous fade safely. Unmounting kills the tween. Initial card mounting uses the card's existing entrance treatment.

October 17, Fishing tiles: the location tiles inside a Fishing area (23 of Fishing's 29 activities) had no badge at all; only Fishing's six ordinary cards did. An unlocked tile now carries the same 86x86 badge on its top-right corner, 30px above the tile and 12px to its right (the next tile is 14px away), for its item while a revealed blocker needs it, and River Bend carries the Wisdom book (in the skill's colour, as on cards) while a Fishing activity that asks for Wisdom is still locked. A locked tile has none. The badges of a tile sit in one box named `FishingTileBadges`, hidden while the area is folded to its title, because they reach into the strip that stays. No new artwork.

October 17, earning an item: each success that sends an item lifts an 80x80 copy of its icon off the badge. The copy rises 115px over 1.25 seconds and fades, the motion the Wisdom book uses (`RewardFeedbackSurface._float_reward_icon`). Before, the copy slid to the locked frame when the frame was on screen and otherwise 180px down the page, the one gain in the game that moved downward.

Final resource validation: `.codex-tmp/resource-corners-wrap-final.log` reports `PROJECT_RESOURCES failures=[]`. Covers actual blocker navigation and training, visible-only allocation, offline completion, legacy/save round trips, corner positions, partial fade opacity, completion hiding, renewed demand, and generated chip cleanup. Raw captures `resource-demand-visible.png`, `resource-demand-fading.png`, `resource-demand-filled.png` and `resource-demand-returned.png` are 1920x1080; the same viewport shows revised Wrap Hands. Material examples include 1080x1920 Obsidian. No agent-owned Godot process remained afterward. Existing fishing mount frame spikes remain outside this artwork check; no claim of a fully optimized release.

October 14 correction: the previous audit verified asset provenance but missed the undersized cover and changed timber/stone silhouettes. Restored the earlier generated broad slabs, corrected shared width-based layout for all nine materials, and retained generated debris and clickable resource holders. No new painted or procedural artwork was introduced.
