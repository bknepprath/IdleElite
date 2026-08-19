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

## Completed migration results

Local implementation and validation completed on August 19, 2026.

| Phase | Result |
|---|---|
| Phase 0 | Fresh-worktree validation, native-1080 migration contracts, Android viewport guards, and mobile text-size contracts pass. |
| Phase 1 | The production viewport and authored UI are 1080 x 1920. Raw production captures were compared with the matching 2160 x 3840 screens, and shared and screen-specific geometry was corrected to preserve the 4K layout and art direction. Coverage includes the menu, settings, every skill page, Hub, pinned, queue, achievements, profile, leaderboard, shop, chat, Thieving heist, and Berry prep surfaces. |
| Phase 2 | Runtime texture imports use Android VRAM compression where appropriate, non-scaled UI disables mipmaps, oversized source files are excluded from exports, and four reviewed runtime atlases were re-authored for 1080p. |
| Phase 3 | Screen-scoped texture ownership, adjacent-swipe caching, bounded lazy mounting, inactive-tree teardown, and navigation-loop resource tests are implemented. Four resource-lifetime cycles remain exactly stable at 2,604 objects, 308 nodes, 8 textures, 0 atlases, and 4 root children. |
| Phase 4 | Extended SFX load by category, music streams are released when song sets change, unused source audio is excluded, and idle warm-cache/static-refresh loops are bounded. |

The strict skills performance test passed three consecutive runs. In the final full-project run, idle work averaged 0.84-0.90 ms per measured frame across the five skills, with p99 at 1.34-1.64 ms. Continuous scrolling remained below the test's 60 FPS p99 budget, and normal and rapid skill swipes completed with no visible placeholders or pending finalization. The isolated cold Fishing render completed in 94.741 ms; its visible cards were immediate and all 18 cards warmed within the bounded warm-up window.

The final preview AAB is 167,728,344 bytes. The prior preview AAB was 200,937,011 bytes, so the migrated package is 33,208,667 bytes smaller, a 16.53% reduction.

`scripts/check-project.ps1` passes with strict skills performance enabled, including native-1080 transition probes and a clean isolated user-data profile. The final preview AAB also exports successfully through `scripts/build-android-preview.ps1` while preserving `window/stretch/mode="viewport"`.

Physical Android PSS, graphics-memory, native-heap, rendering, and touch-offset gates still require a connected phone. No Android device was attached during the final local validation, so the 400-450 MB physical-device target has not been claimed as measured.
