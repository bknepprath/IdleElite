# Fishing tool spacing audit

Moved the shared active-tool layer 64 viewport pixels right. Removed most of the boat's additional leftward offset and applied a fixed 0.75 draw multiplier to its authored animation scales so it fits between the method buttons and the stat column. No texture-bound measurements or per-frame corrective scaling are used.

Restricted the native active-tool button's padded rectangle to the tool lane and removed its accumulating custom minimum size. This keeps the click target from extending over Rocks or beyond the tool layer as the icon moves.

## Visible verification

Ran the production main scene visibly with an isolated save. Fishing level 5 and equipment ownership were test setup; tool selection and starting/stopping Rocks used native mouse input through the actual wallet and method controls.

- Hands, net, bamboo rod, reinforced rod, star rod, boat, and reflection mirror all equipped and started Rocks.
- Inspected the hands, net, all three rod variants, boat, and mirror in raw game captures.
- The first boat capture exposed side clipping; the final boat captures show both ends clear of the mask and a gap from Rocks.
- Captured before, transition, and settled states for each tool, 21 PNGs total, each verified as 1080 x 1920.
- Final visible audit marker: `TOOL_SPACING failures=[]`.
- Focused headless audit also passed: all seven active-tool buttons accepted native touch input and their rectangles did not intersect Rocks. Test script: `.codex-tmp/tool-spacing/hit-audit.gd`; isolated run: `hit-save3`.
- Existing RID/ObjectDB/resource warnings remain at test shutdown; the visible audit had no gameplay script errors.

Captures are in `.codex-tmp/tool-spacing/`, named `<tool>-before.png`, `<tool>-transition.png`, and `<tool>-settled.png`. The final visible run used the isolated `save4` directory there.

The three rods share the same authored icon and animation path. This pass checked the shared two-method Beach layout; it does not establish Android physical-device rendering acceptance.
