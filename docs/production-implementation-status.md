# Production systems implementation

October 24 layout revision: Shape Wooden Parts uses the regular activity layout with a compact recipe row. All nine Building recipe cards now have a centered inward V cut through the face, progress rail and rear plate; other authored building stages reserve space above it. [Current captures and checks](playtests/2026-10-24-production-building-shape.md)

Owner revision: October 24, 2026, restore ordinary legacy activities such as Pocket Couch Coins. Retain special modules with actual production interactions. The earlier request for visual variety does not justify generic enlarged or bobbing replacements.

## Work

- [x] Author 14 production activities, 13 materials and 15 functional production presentations in the activity database
- [x] Remove 32 cosmetic legacy presentations and restore their standard cards without changing rewards, requirements, art or saved IDs
- [x] Implement safe recipe inputs, honey reservation, reusable bottles, activated duration and save compatibility
- [x] Implement location scouting, targeted bait, wax exploration, finite waterwheel processing and tool attachments
- [x] Integrate animated stages into real activity cards while retaining XP, mastery, unlocks and navigation
- [x] Keep existing activity order; no longer force a special presentation every third activity
- [x] Validate live/offline production, interruption, saves, legacy components and material accounting
- [x] Inspect real-main portrait and desktop animation frames for production controls

## Validation

`scripts/test-production-paths.ps1` passes production accounting and the pre-existing medal-strategy regression. Coverage includes interrupted inputs, partial bottles, reusable bottles, activated Honey duration, finite queues, offline exhaustion, bait, equipment, Lantern charges, actual save serialization/restoration, malformed and old saves, cloud protection for permanent equipment, and shared-parts migration. Queued shaping keeps its serialized action ID. Numeric input validation accepts equivalent integer/JSON number values and rejects missing, extra, nonnumeric or unpaid inputs.

Database contracts, structural database audit, activity/UI boundaries, runtime asset paths, performance imports and exported-image resource contracts pass. Database curve-order warnings remain expected because optional production actions are stored after the original catalog and sorted by level in the UI.

Earlier raw real-main evidence is under `outputs/verification/production-paths-oct24/`. Its 47-entry catalog includes the 32 cosmetic presentations subsequently reverted and does not represent their current appearance. `corrections/` contains the shared-parts, spyglass and kiln corrections retained by this rollback. Portrait PNGs are 1080×1920. No screenshots are resized or composited. Current rollback evidence is tracked in `playtests/2026-10-24-activity-presentation-revert.md`.

The first full-catalog run exposed a tap failure on Pick Friendly Lock. Thieving heist routing claimed unrelated releases whenever a heist button was mounted. It now requires the pointer to hit that heist or belong to its active gesture. Pick Friendly Lock starts through the real UI after the fix, and `scripts/test-thieving-heist-click-flow.ps1` passes. The broader catalog run passed the other presentation starts, source links, drag handling, targeted Fishing and desktop Honey interactions. This follow-up resolves its sole failed assertion rather than claiming the original run passed.

Logs: `.codex-tmp/production_paths-regression.log`, `.codex-tmp/medal_strategy_oct24-regression.log`, `.codex-tmp/production-final-capture.log`, `.codex-tmp/production-corrections.log`, `.codex-tmp/production-main-screens.log`. The known sandbox root-certificate warning appears in Godot logs and is excluded from validation failures. No other runtime errors remain in the final correction run.

## Shared parts

Four Softwood produce two Wooden Parts. Spyglass assembly uses two parts plus two Polished Lenses. Lanterns, the Waterwheel and Selective Net also consume parts. The telescope tube is only an internal animation prop. Finished Spyglass art shows its front lens; its far lens is hidden by the opaque eyepiece. See `spyglass-component-art-contract.md` for the corrected art sources and compatibility rules.

Honey packing adds storage control, with the original regeneration strength. These are initial playable recipe costs, with the timing comparison in `connected-production-paths.md`; longer-session economy tuning remains a playtesting task.

## Art contract

Use the approved Building fence and Fighting wheelbarrow assets as style anchors. Preserve the smooth blue character with mitten hands, thick black outlines and three color areas. Generate transparent character poses on one shared cell canvas and ground anchor, plus independent workshop props and item icons. All transient effects remain separate runtime layers. New stages use authored draw boxes; no per-frame bounds scaling.

Current implementation worktree: `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`

This file tracks work in progress, not a release or deployment
