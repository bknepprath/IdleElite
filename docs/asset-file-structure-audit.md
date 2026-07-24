# Asset and File Structure Audit

## Purpose

This audit starts the asset/file naming cleanup pass. The goal is to make paths readable at a human glance, remove confusing repeated folder names where safe, preserve Godot/resource references, and avoid deleting or moving anything that may be scene-bound, imported, exported, generated, or externally consumed.

## Current Naming Clusters

- Runtime game assets live mostly under `assets/content/<domain>/...`, with repeated domain subfolders such as `actions` and `backgrounds` for Fight, Build, Woodcutting, Thieving, Fishing, Events, and Combo content.
- UI/runtime support assets are now consolidated under `assets/content/ui` and `assets/content/ui/navigation-controls`, with source UI work parent-qualified under `docs/art-source/asset-sources/profile-ui-source-assets` and `docs/art-source/asset-sources/game-ui-source-assets`.
- Loading assets live in `assets/loading`, including current untracked Blue Guy loading animation variants and older boot splash references.
- Source and generation work lives mostly under parent-qualified folders in `docs/art-source/asset-sources/...`, which is clearer than the former runtime-shaped mirror.
- Fishing has the densest asset structure: runtime actions/backgrounds/catch-icons/locations/tools/ui plus many source-generation candidates now parent-qualified under `docs/art-source/asset-sources/fishing-module-preview-sources`.
- Extracted UI scripts live in `scripts/ui` and many Godot `.uid` files are currently untracked. These are metadata-adjacent and should not be renamed casually.

## Repeated Folder Names Found

The current tree has repeated leaf folder names that are either intentional domain buckets or confusing mirrors:

| Folder leaf | Count | Initial decision | Rationale |
| --- | ---: | --- | --- |
| `actions` | 12 | Preserve in runtime skill/domain paths; revisit under source archive | Runtime parent folders make these readable (`fight/actions`, `fishing/actions`). Source/archive copies should be parent-qualified if moved. |
| `backgrounds` | 11 | Preserve in runtime skill/domain paths; revisit under source archive | Same as `actions`; safe only with activity database and import reference handling. |
| `ui` | 5 | Merged generic runtime split; parent-qualified source/archive copies | The former runtime `assets/ui` files now live under `assets/content/ui`; source/archive copies were renamed to `profile-ui-source-assets` and `game-ui-source-assets`. |
| `fishing`, `thieving`, `woodcutting` | 3 each | Preserve runtime domains; parent-qualify source/archive copies | Runtime domain names are clear; mirrored docs paths create the confusion. |
| `icons` | 3 | Merged runtime icon folders; parent-qualified source/archive copies | Runtime resource and upgrade icons now live under `assets/content/icons`; docs-side icon sources use `resource-icon-source-assets` and `upgrade-icon-source-assets`. |
| `resources`, `upgrades` | 3 each | Merged runtime icon buckets; parent-qualified source/archive copies | Runtime icon buckets now live under `assets/content/icons`; source copies spell out whether they are resource icon or upgrade icon sources. |
| `assets` | 2 | Renamed docs mirror root | `assets` at repo root is runtime; the former docs mirror is now `docs/art-source/asset-sources`. |
| `content` | 2 | Renamed docs mirror children | Runtime `assets/content` is established; docs source domains now use parent-qualified folders such as `combo-event-source-assets`, `event-source-assets`, `enemy-source-assets`, `hub-source-assets`, and `thieving-source-assets`. |
| `source` | 2 | Renamed icon source children | Icon source folders now use `resource-icon-source-assets` and `upgrade-icon-source-assets` instead of a generic `source/resources` and `source/upgrades` stack. |
| `module-previews` | 2 | Renamed source/archive copy | The docs source-generation copy is now `fishing-module-preview-sources`; runtime-style preview folders should only exist if actual runtime/module preview assets are introduced. |
| `android`, `build`, `combo`, `events`, `fight`, `hub`, `heists`, `trophies`, `enemies` | 2 each | Preserve runtime names; source/archive mirrors parent-qualified where touched | Runtime domains are meaningful; docs-side Android, combo/event, enemy, hub, and thieving source mirrors now use parent-qualified folders. |

Not all repeats are equally bad. Runtime paths like `assets/content/fight/actions` and `assets/content/fishing/actions` are readable because the parent skill supplies the domain. The most confusing repeats are mirror/source roots where `assets/content/...` is nested under `docs/art-source`, because the path reads like runtime content but is really source/archive material.

## Patterns Worth Preserving

- Runtime skill content follows a useful `assets/content/<skill-or-domain>/<asset-kind>/<ordered-domain-name>.png` pattern.
- Numbered action filenames such as `01-scoop-pond-minnows.png` preserve progression order and match activity data expectations.
- Background tiers like `01-early.png`, `02-rising.png`, `03-mid.png`, `04-late.png`, and `05-finale.png` are generic by themselves but become readable inside a skill folder.
- `.png` plus matching `.png.import` pairs must move together when runtime assets are renamed.
- `res://assets/...` paths in scripts, `project.godot`, export presets, tests, and generated docs are authoritative references.
- `docs/art-source` is useful as a non-runtime source archive, but it needs clearer parent-qualified structure before broad cleanup.

## Risky Paths Not To Touch Without Compatibility

- `assets/content/**` runtime art referenced by `docs/activity-database.json`, scripts, tests, export tooling, or runtime-loaded data.
- `assets/loading/**` because boot/loading presentation is player-visible and project-level. The active Blue Guy warmup animation is now tracked, while rejected/source variants remain untracked unless Phase 3.1+ explicitly accepts them.
- `assets/android/**` because export presets reference launcher icon paths directly.
- `project.godot` boot splash path `res://assets/loading/idle-elite-player-hub-launch-loading-screen.png`.
- `.import` files because Godot stores source/remap metadata in them; move/rename only with the paired asset and validate.
- `.gd.uid` files because Godot generated script UIDs may be expected by the editor/project cache.
- Public/export/store assets and build/release outputs unless the export scripts and presets are updated together.
- `docs/activity-database.json` because it is the source of truth for activity data and its asset paths.

## Generated, Import, Cache, And Output Files

The authoritative generated-file staging guide is `docs/generated-file-hygiene.md`, protected by `scripts/check-generated-file-hygiene.ps1`.

- `.import` files are generated metadata but should remain tracked beside tracked runtime assets when the matching source asset is tracked.
- Untracked `.import` files for new dirty assets should not be committed unless their paired asset is intentionally accepted.
- `output/` and `test-results/` are generated local outputs and should be cleaned or ignored rather than reorganized as project source.
- `.codex-tmp/`, `.codex-tools/`, `.godot/`, `builds/`, `release/`, and `play-store/` are not part of the naming cleanup surface unless a specific stale artifact is proven safe to remove.
- `docs/art-source/asset-sources/fishing-module-preview-sources/*-v1` through `*-v8-*` files are candidate-generation history. They are likely cleanup targets, but only after identifying approved/runtime descendants and preserving any docs that explain final selections.
- Godot `.import` metadata is no longer tracked under `docs/art-source/asset-sources/**`. This archive is under `docs/art-source/.gdignore`, and the removed metadata was stale after the source archive rename.

## Phase 2.1 Ownership Classification

This pass inspected `docs/art-source`, `assets/loading`, `assets/android`, `android/build/res/mipmap`, `project.godot`, `export_presets.cfg`, and import metadata without moving or deleting assets.

| Surface | Current ownership | Preserve / rename / clean / skip |
| --- | --- | --- |
| `docs/art-source/asset-sources/**` | Tracked source/provenance archive with 141 PNGs, 9 Markdown notes, 3 `.gdignore` files, and `moved-files.txt`. Folder names are already parent-qualified by domain: Android launcher, combo/event, enemy, fishing module preview, game UI, hub, profile UI, resource icon, thieving, and upgrade icon sources. | Preserve as source archive. Phase 2.2 pruned stale docs-side `.import` metadata; future cleanup may remove only proven bad generations after reference and hash checks. |
| `docs/art-source/asset-sources/fishing-module-preview-sources/**` | Dense generation history for fishing module previews, including v1-v8 contact sheets and per-area candidates. Docs such as `docs/fishing-module-art-suite-v1.md` still reference these files. | Preserve until approved descendants and doc references are mapped. Candidate for later pruning, not deletion by broad sweep. |
| `docs/art-source/asset-sources/android-launcher-source-assets/**` | Android launcher provenance. The stale `.import` metadata that pointed at `res://assets/android/launcher-adaptive-clickable-preview-432.png` was removed in Phase 2.2. | Preserve source PNGs and verify before using as runtime launcher input. Do not wire to export presets unless Phase 3.2 owns the change. |
| `assets/loading/idle-elite-player-hub-launch-loading-screen.png` | Tracked project boot splash referenced by `project.godot`. | Preserve exactly unless Phase 3.1 changes boot splash paths and validates Godot startup. |
| `assets/loading/idle-elite-loading-screen.png` | Tracked older loading image with matching import metadata. No direct reference found in `project.godot`, `export_presets.cfg`, or current scripts during this pass. | Keep documented as candidate stale runtime asset; do not delete until Phase 3.1 hash/reference review. |
| `assets/loading/blue-guy-flex-loading-spritesheet.png` and `blue-guy-flex-speech-bubble-blank.png` | Tracked runtime warmup animation assets referenced by `scripts/app/boot_warmup_runtime.gd` and prewarmed by `scripts/main.gd`. | Preserve with their `.import` files. Do not rename without updating the boot animation owner, warmup preload list, tests, and validation notes. |
| `assets/loading/blue-guy-flex-*before-*`, `blue-guy-flex-loading-spritesheet-source.png`, and `blue-guy-flex-speech-bubble.png` | Dirty/untracked variants, source image, and speech-bubble work files with `.import` metadata. | Treat as unresolved loading-source cluster. Do not delete until active runtime files and source/provenance needs are confirmed. |
| `assets/android/launcher-main-clickable-192.png`, `launcher-adaptive-foreground-clickable-432.png`, `launcher-adaptive-background-clickable-432.png` | Tracked Android launcher assets referenced directly by `export_presets.cfg`. Phase 3.2 confirmed each clickable file is byte-identical to the matching non-clickable same-size variant. | Preserve exact paths; the export preset is the active contract. Do not rename to remove `clickable` unless the preset, import metadata, docs, and Android validation all move together. |
| `assets/android/launcher-main-192.png`, `launcher-adaptive-foreground-432.png`, `launcher-adaptive-background-432.png` | Tracked non-clickable launcher aliases with import metadata. No direct export preset reference found, and Phase 3.2 hash checks showed they duplicate the active clickable launcher images by size/role. | Keep as fallback aliases for now. They are safe future cleanup candidates only if export/store docs confirm no external use and the paired `.import` files are handled together. |
| `android/build/res/mipmap/icon*.png` | Tracked generated/export-side Android resources. | Skip for readability cleanup unless an Android export package explicitly owns regeneration. |
| `.import` metadata under `docs/art-source/asset-sources/**` | Removed in Phase 2.2 after reference checks. The archive is under `.gdignore`, runtime code does not reference these metadata files, and many entries pointed at stale runtime paths. | Keep untracked if Godot regenerates any locally. Do not recommit docs-side `.import` files unless a future package proves they carry needed provenance. |

## Duplicate Or Unused Cleanup Suspects

- Blue Guy loading variants in `assets/loading` include names like `before-frame2-smaller-right`, `before-frame4-up5`, `before-frame4-up8`, and `source`. These remain dirty/untracked source or rejected variants after Phase 3.1 accepted the active spritesheet and blank bubble.
- `docs/art-source/asset-sources/fishing-module-preview-sources` has many repeated version ladders per fishing area. These should be reduced to approved source/archival names once final descendants and explanatory docs are preserved.
- `docs/art-source/asset-sources/...` no longer tracks `.import` files. The removed metadata often pointed at `res://assets/...` rather than the docs path and was not useful provenance after the archive rename.
- Runtime and art-source folders used to both contain generic `assets/content/ui` and `assets/ui` source paths. The docs-side copies are now parent-qualified, and the remaining runtime `assets/ui` files have been merged into `assets/content/ui`.
- Android launcher duplicate detection is complete for Phase 3.2: the 192px main icon pair shares SHA-256 `3079549F60B3330B04F588F1F81326BE6A9168DDE4931E370A3AA9C1E4602C75`, and all four 432px adaptive files share SHA-256 `19E561EAC4BCA948AE47FEFC539AE915752867F1935BF8964EF59A295E72B314`. Other duplicate suspects still need content-hash verification before deletion.

## First Safe High-Value Targets

1. Done: rename the source/archive mirror root from `docs/art-source/assets` to `docs/art-source/asset-sources`, then update docs references. This attacks the repeated `assets/content` confusion without touching runtime `res://assets` paths.
2. Clean or ignore generated local folders `output/` and `test-results/` after confirming they are untracked outputs and not needed artifacts.
3. Done for runtime warmup: accepted the active Blue Guy spritesheet and blank speech bubble, folded the loading animation into `scripts/app/boot_warmup_runtime.gd`, updated `scripts/main.gd` warmup mounting/prewarm paths, and protected the flow in `scripts/test-performance-regressions.ps1`. Remaining untracked Blue Guy variants are source/rejected candidates and should not be committed without a separate provenance decision.
4. Done: parent-qualify the fishing module source-generation folder as `docs/art-source/asset-sources/fishing-module-preview-sources`.
5. Done: profile/avatar UI sources now live in `profile-ui-source-assets`, broader game UI sources now live in `game-ui-source-assets`, and the runtime `assets/ui` split has been merged into `assets/content/ui`.

## Reference Evidence Collected

- Directory grouping found repeated leaf names: `actions` 12, `backgrounds` 11, `ui` 5, several domain folders 2-3 times.
- `rg` found many direct `res://assets` and `assets/content` references in `scripts/main.gd`, `scripts/app/boot_warmup_runtime.gd`, tests, export presets, generated docs data, and store-asset tooling.
- `export_presets.cfg` directly references Android launcher icon paths and excludes several source/preview asset patterns from builds.
- `project.godot` still references the older loading splash path.
- Phase 3.1 accepted the Blue Guy warmup animation for the in-game boot warmup overlay. `project.godot` still references the older player-hub launch loading screen as the native Godot boot splash; do not conflate that project splash with the scripted warmup overlay.
- Phase 2.1 confirmed Android export presets currently use the clickable launcher assets, while `android/build/res/mipmap/icon*.png` are export-side outputs and not a readability cleanup surface.
- Phase 3.2 kept Android launcher asset paths stable, documented the active clickable export contract, and fixed the leaderboard/export safety check to read `permissions/internet=true` as a line-based preset entry.
- Phase 2.2 removed 111 tracked `.import` metadata files under `docs/art-source/asset-sources/**` after confirming the archive has `.gdignore`, runtime references do not use those metadata files, and `moved-files.txt` could preserve the source PNG provenance without listing removed metadata.
- Existing dirty/untracked files include navigation-control imports, Blue Guy loading files/imports, UI script UIDs, `output/`, and `test-results/`; these should remain unstaged unless a cleanup step explicitly owns them.

## Working Rules For Future Commits

- Before renaming or deleting an asset, run `rg` for the exact path, basename, and any `res://` form.
- Move assets and their `.import` files together, then validate with focused reference checks and `.\scripts\check-project.ps1`.
- Prefer one folder family or one asset cluster per commit.
- Do not change image/audio content while doing name-only cleanup.
- Do not delete source-generation candidates until an approved/runtime replacement and all references are known.
- If a repeated folder name remains, document why the parent context makes it readable or rename it with a parent-qualified convention.
