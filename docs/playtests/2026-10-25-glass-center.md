# Glass icon center repair

Repaired the existing Glass material icon using built-in ImageGen, preserving the oval, tilt, cyan palette, black outline, lower rim and white reflection. The center no longer has a dirty low-opacity patch. Center alpha increased from 80 to 254; the full central 120x120 region is at least 250. The exterior remains transparent. The original runtime path and 512x512 canvas are unchanged, so all existing inventory, input/output and recipe uses receive the repair.

Contract, exact prompt, before/master files, packing script and provenance are under `output/imagegen/glass-center-oct25/`. Only uniform full-canvas downsampling was used after generation.

Godot import completed through the safe wrapper with tracked import changes preserved. Actual-main `scripts/tests/glass_icon_capture.gd` reached Melt Sand through the real UI, started production and captured the repaired Glass on the wooden inventory background. Shape Bottles shows the same icon at a larger size on its white input card. Both raw 1080x1920 images were inspected: `outputs/verification/glass-center-oct25/glass-production-inventory.png` and `glass-recipe-input.png`. Capture checks and runtime asset paths passed. The unrelated existing full-project Privacy text-size failure is unchanged.

No recipes, balance, layouts, saves or rendering settings changed. No phone update or release publication.
