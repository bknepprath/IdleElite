# 1080p performance migration

## Objective

Reduce Android launch and steady-state memory by re-authoring the game for a 1080 x 1920 base viewport while keeping `window/stretch/mode="viewport"` and the Mobile renderer. Do not use `canvas_items`, a root-scale workaround, a logical-canvas override, or a nested viewport as a substitute for migrating layout values.

## Measured baseline

The August 2026 physical-device investigation recorded the following results on the Galaxy S24 Ultra preview package:

| State | Total PSS | Graphics memory |
|---|---:|---:|
| Original cold launch | 1,579 MB | 1,150 MB |
| Accepted loading fixes | 1,046 MB | 636 MB |
| Half-resolution diagnostic | about 800-852 MB | about 426-437 MB |

The half-resolution diagnostics were not accepted because runtime scaling and `canvas_items` produced layout defects, framebuffer tearing, blank rendering, or unbounded allocation growth. An empty 2160 x 3840 scene measured about 493 MB, confirming that the current render-target size is a material part of the remaining floor.

## Required invariants

- Keep `window/stretch/mode="viewport"`.
- Keep `window/stretch/aspect="expand"` unless physical-device validation proves a reviewed replacement.
- Keep the Mobile renderer unless the Android release-critical validation process approves a change.
- Preserve production package data. Install only `com.idleelite.game.preview` during device testing.
- Keep phone-visible body text at least 48 px, help and status text at least 52 px, and titles at least 60 px at the 1080-wide base viewport.
- Use the production `res://scenes/main.tscn` hierarchy for visual evidence.

## Execution phases

### Phase 0: clean-checkout baseline

- Make a fresh linked worktree parse and validate without relying on another checkout's `.godot` cache.
- Record the current 2160 x 3840 baseline and the set of authored layout assumptions.
- Add migration contracts that reject `canvas_items`, legacy project viewport dimensions, and undersized mobile text after the viewport cutover.

### Phase 1: 1080 x 1920 layout migration

- Change the project base viewport and central canvas contract to 1080 x 1920.
- Re-author the shared navigation shell, skill header, card stack, bottom navigation, overlays, and input mapping at native 1080 coordinates.
- Convert the Hub, menu, pinned, queue, settings, shop, achievements, profile/chat, tutorial, and temporary-event surfaces screen by screen.
- Update real-game capture and geometry tests so they validate the native 1080 coordinate system without a runtime downscale.
- Physical-device gate: no tearing, clipping, overlap, blank frame, allocation growth, or input offset. Target at most 700 MB cold PSS.

### Phase 2: texture pipeline

- Inventory exported texture dimensions, formats, mipmaps, and maximum displayed sizes.
- Downsample runtime art to the largest reviewed 1080-wide display requirement.
- Use Android ETC2/ASTC VRAM compression for large runtime artwork.
- Disable mipmaps for UI textures that are not substantially reduced during play.
- Exclude source-resolution and diagnostic artwork from Android exports.
- Physical-device gate: target at most 500 MB cold PSS with visual parity at 1080 x 1920.

### Phase 3: resource lifetime

- Replace permanent global texture residency with screen- and skill-scoped ownership and eviction.
- Keep only the current screen, current skill, visible cards, and immediately adjacent swipe content mounted.
- Tear down inactive screen trees and reconstruct them when opened.
- Measure cold launch, each top-level screen, repeated navigation, and return-to-origin memory.

### Phase 4: audio and native cleanup

- Load SFX on demand and stream music.
- Exclude unused source WAV files from Android exports.
- Remove remaining native allocations that grow after repeated navigation or activity changes.
- Final physical-device gate: 400-450 MB cold and steady-state PSS, with no sustained growth during the navigation stress loop.

## Validation at every player-visible checkpoint

1. Run `scripts/check-crash-audit-contracts.ps1` and the focused layout tests.
2. Run `scripts/check-project.ps1` before merging a completed phase.
3. Install with `scripts/install-android-phone-debug.ps1`.
4. Capture and inspect the real game at 1080 x 1920 through the production main scene.
5. Record cold PSS, graphics memory, native heap, and repeated-navigation PSS with `scripts/measure-android-memory.ps1` against `com.idleelite.game.preview`.
6. Verify that no agent-owned headless Godot process remains.

## Migration validation status

Local implementation and validation status recorded on August 19, 2026.

| Phase | Result |
|---|---|
| Phase 0 | Fresh-worktree validation, native-1080 migration contracts, Android viewport guards, and mobile text-size contracts pass. |
| Phase 1 | The production viewport and authored UI are 1080 x 1920. Raw production captures were compared with the matching 2160 x 3840 screens, and shared and screen-specific geometry was corrected to preserve the 4K layout and art direction. Coverage includes the menu, settings, every skill page, Hub, pinned, queue, achievements, profile, leaderboard, shop, chat, Thieving heist, and Berry prep surfaces. |
| Phase 2 | The preview AAB contains all 653 images selected by the Android preset and none of the 1,763 excluded images. It contains 387 ASTC and 266 default texture payloads. The complete [texture inventory](performance-1080p-texture-inventory.md) records explicit decisions for every included image: 96 are downsampled at import, 16 retain reviewed fixed-cell animation canvases, four are reviewed 1080p derivatives, and 537 are already bounded by the native viewport. All 47 pending UI/icon/loading mipmap reviews were resolved by disabling those mipmaps. |
| Phase 3 | Screen-scoped texture ownership, adjacent-swipe caching, bounded lazy mounting, inactive-tree teardown, and navigation-loop resource tests are implemented. Across four full navigation cycles, the live node count remains fixed at 446, texture residency settles from 13 to 10 after the first cycle, atlas count remains 0, and the dynamic page root remains fixed at 4 children. Object count rises from 3,088 to 3,154 and remains inside the regression gate. |
| Phase 4 | Extended SFX load by category, music streams are released when song sets change, unused source audio is excluded, and idle warm-cache/static-refresh loops are bounded. |

The strict skills performance test passed three consecutive runs. In the final strict repetition, idle work averaged 0.85-0.94 ms per measured frame across the five skills. Fight scrolling completed at 4.57 ms average, 9.80 ms p99, and 12.05 ms maximum with no jank frames; Fishing scrolling completed at 3.74 ms average, 14.35 ms p99, and 15.93 ms maximum with no jank frames. Normal and rapid skill swipes completed with no pending finalization and stayed inside their bounded placeholder and jank gates.

Fresh raw 1080 x 1920 production captures were compared to Lanczos-downsampled 2160 x 3840 references after the final performance changes. Mean absolute pixel error was 6.59 for Fighting, 6.51 for Building, 7.11 for Woodcutting, 4.72 for Fishing, and 7.36 for Thieving. The activity-card shell, card depth, locked-state rig, and 28 px mastery rail align within one pixel of the reference geometry. Text that would have fallen below the 1080-wide mobile readability contract remains at its required minimum size.

The final preview AAB is 154,737,747 bytes. The prior preview AAB was 200,937,011 bytes, so the migrated package is 46,199,264 bytes smaller, a 22.99% reduction.

`scripts/check-project.ps1` passes, including native-1080 transition probes, activity and medal behavior, resource lifetime, swipe behavior, save normalization, and a clean isolated user-data profile. The strict skills gate also passes independently for three consecutive runs. The final preview AAB exports successfully with Godot 4.7.1 through `scripts/build-android-preview.ps1`, with an empty stderr log, while preserving `window/stretch/mode="viewport"`.

Physical Android PSS, graphics-memory, native-heap, rendering, and touch-offset gates still require a connected phone. No Android device was attached during the final local validation, so the 400-450 MB physical-device target has not been claimed as measured. The release-signing gate also requires `IDLE_ELITE_KEYSTORE_PASSWORD`; that secret was not available in the validation environment, so only the preview AAB was exported.
