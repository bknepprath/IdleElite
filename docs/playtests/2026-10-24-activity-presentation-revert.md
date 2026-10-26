# Activity presentation rollback, October 24

Worktree: `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`

The owner rejected cosmetic replacements of ordinary activities, using Pocket Couch Coins as an example. Removed 32 presentation records from the authoritative activity database. Every other action field was compared with the pre-edit value and remains unchanged: IDs, order, requirements, rewards, success chances, timing, art and art framing. Existing mastery and save keys are retained.

Retained 15 presentations for the 14 new production activities and existing Honey activity. Their purpose is resource production, recipe input/output, Honey storage/use, scouting/bait/equipment, light consumption or the Waterwheel queue. The earlier two-normal-cards-in-a-row limit is no longer enforced. Existing combat arenas, Fishing, recovery and passive modules are unaffected.

## Restored activities

Fighting: Wrestle Stuck Gate Latch, Square Up With Rake, Unstuck Root Cellar Door, Hold Pumpkin Line, Face The Entire Farm At Once, Rematch Buff Hay Bale

Thieving: Pocket Couch Coins, Pick Friendly Lock, Heist The Museum Gift Shop, Remove Competition, Crack The Shipwrights Lockbox, Rob The Alien Spaceships Bank, Forge A Receipt For The Moon, Crack Dimensional Vault, Pickpocket Dimensional God

Building: Patch Fence, Repair Small Shack, Build Town Notice Board, Raise Guild Hall, Build Elite Tower, Add Second Elite Tower On Top, Construct Underground Town, Build Weatherproof Weather, Build Builder Building

Woodcutting: Trim Overconfident Shrub, Fell Skinny Pine, Split Lightning Struck Cedar, Clear Mystic Timberland, Harvest Tree Apology, Carve The Guilds Trophy Oar, Clear Forest Legal, Harvest Ironwood

## Verification

Database contracts and the structural audit pass with zero missing assets. Existing curve/order warnings remain. `scripts/test-production-paths.ps1` passes both `PRODUCTION_PATHS failures=[]` and `MEDAL_STRATEGY failures=[]`. Production accounting, queues, equipment, save compatibility and the earlier medal strategy remain covered.

Actual-main portrait captures use `scripts/tests/action_art_oct22.gd` through `run-godot-safe.ps1 --visible-game`, with muted audio and isolated save storage. Requested IDs are limited to the 32 restored cards. Raw PNGs and the capture manifest are under `outputs/verification/activity-presentation-revert-oct24/`; log `.codex-tmp/activity-presentation-revert.log`. Early runs exposed test setup errors: navigating to an unrequested skill and letting the Halloween greeting consume the first menu tap. The fixture now skips unrequested skills and dismisses that greeting through actual input before navigation.

Final capture passes: `ACTION_ART_AUDIT failures=[]`, 32 requested actions captured, all 32 using their portrait renderer, every PNG exactly 1080×1920. The portrait containment and authored-framing checks pass. Inspected representative restored cards from all four affected skills, including the final Pocket Couch Coins capture. No Godot process remained after validation.

This rollback has not been installed on the phone, exported or published.
