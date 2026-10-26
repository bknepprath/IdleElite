# Building progression order

The opening order is Stack Bricks, Hammer Nails, Gather Sand, Saw Planks, Patch Fence, Study Blueprint, Repair Small Shack, Sharpen the Pencil, Melt Sand, Install Door That Mostly Opens, Tier 1 banner, Shape Bottles, then Build Bridge Over Tiny Puddle. Building levels are respectively 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 and 11 for those activities. Source order resolves the two level-11 cards. All remaining activities keep their prior levels and relative order.

Gather Sand retains Fishing 4 and its Fishing XP reward. Saw Planks retains Woodcutting 2; Study Blueprint retains Thieving 4. Existing IDs, resource projects, mastery balances, kiln construction cost, production recipes and reward values are preserved. Loot the Beehive is unchanged.

Checks passed:
- Activity database contracts and audit, zero missing assets
- Actual main scene loaded order and rendered entry order
- Updated Building requirements fail one level below and pass at their new level
- Gather Sand still fails its Fishing requirement below Fishing 4
- Tier 1 banner follows Install Door That Mostly Opens, followed immediately by Shape Bottles
- Real page captured silently with the safe launcher's Dummy audio driver
- All five raw captures are 1080 by 1920; inspected Gather Sand/Saw Planks/Patch Fence, Sharpen the Pencil/Melt Sand, and Tier 1/Shape Bottles
- No agent-owned Godot process remained after the test

Evidence: `outputs/verification/building-order-oct26/result.json` and neighboring PNGs. Local change only; no install or publication.
