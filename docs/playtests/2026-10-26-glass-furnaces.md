# Glass furnace backgrounds

Replaced the shared empty workbench background on Melt Sand and Shape Bottles with distinct glass furnace workshops. Melt Sand has a melting crucible; Shape Bottles has a reheating furnace and blowpipe. Generated with built-in ImageGen, using the approved hub decor and market stall style anchors. Runtime plates are 768 by 344, with master assets and prompts in `output/imagegen/glass-furnaces-oct26`.

Validation:
- Activity database contracts pass; database audit reports zero missing assets
- Actual main scene, muted through the safe launcher's Dummy audio driver, captured at native 1080 by 1920
- Both activities tested through their real output controls, ingredient hop, conversion hop and output delivery
- Exact output credits, existing medal and stats placement, and hidden original action artwork pass
- `outputs/verification/furnace-backgrounds-oct26/result.json` has no failures
- Inspected both active captures: furnace openings remain visible between the action boxes and all background art stays within the existing production mask
- No agent-owned Godot processes remain

Local source and assets only; no phone install, release export or publication
