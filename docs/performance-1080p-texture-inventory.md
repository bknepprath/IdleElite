# 1080p exported texture inventory evidence

Generated on 2026-08-19 for the Android Release preset and the preview AAB at `builds/android/idle-elite-preview-debug.aab`.

The complete per-image evidence is in `docs/performance-1080p-texture-inventory.csv`. It records preset inclusion, AAB inclusion, AAB remap format and payload presence, source dimensions and bytes, Godot import mode, Android compression target, mipmaps, import size limit, statically discovered maximum display size, and the downsample decision.

## Artifact identity

| Field | Value |
|---|---:|
| AAB bytes | 154,737,747 |
| AAB last write UTC | 2026-08-20T04:02:15Z |
| AAB SHA-256 | `f5809418270cee57096c53adbd057097aae4f5b7c7c35d27ee2a3ffc833bcda3` |
| Preset | Android Release |
| Preset export filter | `all_resources` |

## Inclusion result

| Check | Count |
|---|---:|
| Git-tracked image sources evaluated | 2,416 |
| Included by the Android preset | 653 |
| Excluded by the Android preset | 1,763 |
| Image `.import` entries in the AAB | 653 |
| Preset-included images found in the AAB | 653 |
| Preset-included images missing from the AAB | 0 |
| Preset-excluded images absent from the AAB | 1,763 |
| Preset-excluded images unexpectedly present | 0 |
| AAB texture payloads found | 653 |
| AAB texture payloads missing or unresolved | 0 |

The AAB verification reads the resource-relative image `.import` entries from the install-time asset pack and verifies that each remapped `.ctex` payload is present. This provides artifact-level inclusion evidence rather than relying only on the preset text.

## Dimensions and import format

The included source images total 225,267,016 bytes before Godot import. Dimensions were measured for all 653 included sources; none are unknown.

| Import evidence | Count |
|---|---:|
| Git-tracked `.import` sidecar | 653 |
| Existing but untracked `.import` sidecar observed | 0 |
| VRAM Compressed in the worktree and ASTC in the AAB | 387 |
| Lossless in the worktree and default `.ctex` in the AAB | 266 |
| Mipmaps disabled | 428 |
| Mipmaps enabled | 225 |
| Enabled mipmaps on UI, icon, or loading paths requiring review | 0 |

All 653 included images have Git-tracked import settings, so the captured import policy is reproducible from a clean checkout.

## Static display-size coverage

| Discovery status | Count |
|---|---:|
| Reviewed static maximum | 20 |
| Partial static placement evidence | 158 |
| No static maximum discovered | 475 |

Static discovery covers literal production `_image(..., Vector2(...))` placements, constant image paths used by those calls, and activity art routed through `ActionArtUi.ACTION_ART_SIZE`. Dynamic sizes, calculated layouts, animation-state scaling, and code paths that assign textures separately from control sizes remain outside this proof.

The four reviewed 1080p derivatives are:

| Runtime image | Source dimensions | Reviewed maximum display | AAB format | Mipmaps | Decision |
|---|---:|---:|---|---|---|
| `assets/content/thieving/heists/thieving-trophy-heist-backgrounds-1080p.png` | 4320 x 619 | 1080 x 440 per atlas cell | ASTC | disabled | reviewed atlas |
| `assets/content/ui/berry-mode-borders-1080p.png` | 1080 x 1920 | 1080 x 1920 | ASTC | disabled | reviewed full-viewport derivative |
| `assets/content/ui/profile-avatar-blue-guy-spritesheet-1080p.png` | 1280 x 512 | 155 x 155 per atlas cell | ASTC | disabled | reviewed atlas |
| `assets/content/ui/profile-avatar-game-objects-spritesheet-1080p.png` | 1280 x 512 | 155 x 155 per atlas cell | ASTC | disabled | reviewed atlas |

Sixteen additional animation atlases retain their authored fixed-cell canvases. Their frame boxes and ground anchors are part of the animation-scale contract, so they are not resized from measured alpha bounds.

## Downsample decisions

| Decision | Count |
|---|---:|
| Re-authored and reviewed | 4 |
| Downsampled by Godot import size limit | 96 |
| Retain reviewed authored fixed-cell atlas | 16 |
| Keep source already bounded by the native viewport | 537 |
| Review pending | 0 |

Of the 96 downsampled images, 28 use `process/size_limit=768`, 12 use `process/size_limit=1024`, and 56 use `process/size_limit=1080`. Ten already viewport-bounded sources also retain older 768 or 1024 limits.

Every included image now has an explicit decision. Sources larger than the native viewport are either downsampled at import, retained as reviewed fixed-cell atlases, or represented by reviewed 1080p derivatives. UI, icon, and loading textures no longer have review-pending mipmaps.

## Reproduction

The workflow is read-only and does not launch Godot or modify import state.

```powershell
.\scripts\audit-exported-image-assets.ps1 `
    -Format Summary `
    -ArtifactPath builds/android/idle-elite-preview-debug.aab

.\scripts\audit-exported-image-assets.ps1 `
    -CheckSnapshot `
    -ArtifactPath builds/android/idle-elite-preview-debug.aab

.\scripts\audit-exported-image-assets.ps1 `
    -Format Json `
    -IncludeExcluded `
    -ArtifactPath builds/android/idle-elite-preview-debug.aab
```

`ExportStatus` is derived from the named preset's `all_resources` filter and exclusions. `ArtifactStatus`, `ArtifactImportFormat`, and `ArtifactPayloadStatus` are read from the supplied AAB. The workflow does not decode GPU texture payloads, measure runtime residency, or infer a complete maximum display size from dynamic layouts.
