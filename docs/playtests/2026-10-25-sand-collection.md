# Sand collection and factory header, October 25

Melt Sand uses `presentation.stats_position: top-center`. Its existing XP and time controls are centered on the module's top row, clear of the title, medal and input/output boxes. Other converter layouts retain their existing placement unless configured with that position. Recipes, construction requirements, XP and timing remain unchanged.

Ordinary resource gathering now uses the existing material collection boxes even when the action is excluded from tier-medal indexing. That tier flag no longer suppresses gathering feedback. Gather Sand and Collect Beeswax were the two affected ordinary gathering actions. Existing dedicated converter, grove, Rockslide and Honey inventories retain their own controls and feedback.

Gather Sand opens its collection box when started, shows current Sand inventory and uses the existing curved collection flyer/pulse on an actual successful harvest. It closes on stopping. Its new sand background is configured in the authoritative material definition; the material loader now respects a supplied background instead of replacing every production material's background with wood. Unspecified materials keep their previous default. Gather Sand remains under its existing Building action ID and keeps its Fishing requirement; no save IDs or skill placement were changed.

New art: `assets/content/ui/mats/mat-bg-sand.png`, 512x512 opaque background, generated with the approved hub-decor style reference and existing material-box context. The box mask, border, Sand icon and text are separate production controls. Contract and source master: `output/imagegen/sand-collection-oct25/`.

Validation:

- `sand_collection_capture.gd` boots the real main scene, reaches Building through actual navigation, and checks the Melt Sand header position and clear ingredient/output controls
- Factory output selection still starts a real reserved batch
- Gather Sand starts through its actual card, opens the box and produces a real success-driven flyer
- Successful gathering grants exactly two Sand, with no UI-side award or synthetic completion
- Stopping closes the box; Collect Beeswax follows the same opening rule
- All ordinary material-gathering actions checked for box eligibility
- `production_paths.gd` passed recipe, payment, rewards and save regressions
- Required database contracts, activity audit and affected-screen audit executed

Raw 1080x1920 evidence: `outputs/verification/sand-collection-oct25/final/`, including `melt-sand-idle.png`, `gather-sand-idle.png`, `gather-sand-open.png`, `gather-sand-dropping.png`, `gather-sand-collected.png`, `gather-sand-closed.png` and `beeswax-collection-open.png`. All animation states come from the same actual-main run. No phone installation or release publication was performed.
