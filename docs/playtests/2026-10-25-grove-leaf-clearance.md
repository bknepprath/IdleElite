# Smaller gold leaves and outline clearance

Reduced the fixed gold-leaf draw box from 56px to 36px (36% smaller in each dimension). Preserved the existing single-color stemless silhouette and one/two/three bonus levels. Each of the six tree types now has its own three authored anchor points on the shared 512px tree canvas. Placement remains attached to the same tree transform during sway, falling and fading.

`grove_leaf_clearance.gd` checks every nontransparent source leaf pixel against the actual tree texture at all 18 placements and three authored tree sizes (200, 216 and 224px). It also checks a six-source-pixel clearance around each sample against transparency and near-black ink. All 54 combinations passed. Measurements validate positions only; no runtime alpha-bounds scaling or per-frame correction is used.

The real-main `grove_gold_capture.gd` check passed with actual Woodcutting navigation, all six tree types, all leaf counts and an actual fall/harvest cycle. Inspected raw 1080x1920 screenshots show leaves inside the colored foliage, clear of outer and internal black lines. Required Woodcutting screen audit passed. No gameplay data, bonus balance, save format, phone install or release publication changed.

Evidence: `outputs/verification/grove-inset-gold-leaves-oct25/final/`, including all six `*-leaf-levels.png`, `leaves-standing.png`, `leaves-follow-falling-tree.png` and `leaves-cleared-after-harvest.png`. These animation states came from one actual-main run with muted preview audio.
