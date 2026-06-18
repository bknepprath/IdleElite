# Asset and File Structure Audit

## Purpose

This audit starts the asset/file naming cleanup pass. The goal is to make paths readable at a human glance, remove confusing repeated folder names where safe, preserve Godot/resource references, and avoid deleting or moving anything that may be scene-bound, imported, exported, generated, or externally consumed.

## Current Naming Clusters

- Runtime game assets live mostly under `assets/content/<domain>/...`, with repeated domain subfolders such as `actions` and `backgrounds` for Fight, Build, Woodcutting, Thieving, Fishing, Events, and Combo content.
- UI/runtime support assets are split between `assets/ui`, `assets/content/ui`, `assets/content/ui/navigation-controls`, `assets/icons`, and `assets/content/icons`.
- Loading assets live in `assets/loading`, including current untracked Blue Guy loading animation variants and older boot splash references.
- Source and generation work lives mostly under `docs/art-source/asset-sources/...`, which is clearer than the former `docs/art-source/assets/...` mirror but still contains some runtime-shaped subfolders that need follow-up cleanup.
- Fishing has the densest asset structure: runtime actions/backgrounds/catch-icons/locations/tools/ui plus many source-generation candidates now parent-qualified under `docs/art-source/asset-sources/fishing-module-preview-sources`.
- Extracted UI scripts live in `scripts/ui` and many Godot `.uid` files are currently untracked. These are metadata-adjacent and should not be renamed casually.

## Repeated Folder Names Found

The current tree has repeated leaf folder names that are either intentional domain buckets or confusing mirrors:

| Folder leaf | Count | Initial decision | Rationale |
| --- | ---: | --- | --- |
| `actions` | 12 | Preserve in runtime skill/domain paths; revisit under source archive | Runtime parent folders make these readable (`fight/actions`, `fishing/actions`). Source/archive copies should be parent-qualified if moved. |
| `backgrounds` | 11 | Preserve in runtime skill/domain paths; revisit under source archive | Same as `actions`; safe only with activity database and import reference handling. |
| `ui` | 5 | Audit and likely parent-qualify where ambiguous | `assets/ui`, `assets/content/ui`, `docs/art-source/asset-sources/ui`, and `docs/art-source/asset-sources/content/ui` overlap conceptually. |
| `fishing`, `thieving`, `woodcutting` | 3 each | Preserve runtime domains; parent-qualify source/archive copies | Runtime domain names are clear; mirrored docs paths create the confusion. |
| `icons` | 3 | Audit before rename | `assets/icons` and `assets/content/icons` have different runtime roles but their names are easy to confuse. |
| `resources`, `upgrades` | 3 each | Preserve under icon source/runtime clusters until references are mapped | These are narrow enough inside `icons`, but source/runtime mirrors need clearer root naming. |
| `assets` | 2 | Renamed docs mirror root | `assets` at repo root is runtime; the former `docs/art-source/assets` mirror is now `docs/art-source/asset-sources`. |
| `content` | 2 | Rename through docs mirror cleanup | Runtime `assets/content` is established; source mirror should stop repeating it literally. |
| `source` | 2 | Parent-qualify after icon-source audit | `source` is too generic outside its parent; likely should become `resource_icon_sources` / `upgrade_icon_sources` or similar. |
| `module-previews` | 2 | Renamed source/archive copy | The docs source-generation copy is now `fishing-module-preview-sources`; runtime-style preview folders should only exist if actual runtime/module preview assets are introduced. |
| `android`, `build`, `combo`, `events`, `fight`, `hub`, `heists`, `trophies`, `enemies` | 2 each | Preserve runtime names; rename only source/archive mirrors | Runtime domains are meaningful; repeated docs/art-source mirrors are the cleanup target. |

Not all repeats are equally bad. Runtime paths like `assets/content/fight/actions` and `assets/content/fishing/actions` are readable because the parent skill supplies the domain. The most confusing repeats are mirror/source roots where `assets/content/...` is nested under `docs/art-source`, because the path reads like runtime content but is really source/archive material.

## Patterns Worth Preserving

- Runtime skill content follows a useful `assets/content/<skill-or-domain>/<asset-kind>/<ordered-domain-name>.png` pattern.
- Numbered action filenames such as `01-scoop-pond-minnows.png` preserve progression order and match activity data expectations.
- Background tiers like `01-early.png`, `02-rising.png`, `03-mid.png`, `04-late.png`, and `05-finale.png` are generic by themselves but become readable inside a skill folder.
- `.png` plus matching `.png.import` pairs must move together when runtime assets are renamed.
- `res://assets/...` paths in scripts, `project.godot`, export presets, tests, and generated docs are authoritative references.
- `docs/art-source` is useful as a non-runtime source archive, but it needs clearer parent-qualified structure before broad cleanup.

## Risky Paths Not To Touch Without Compatibility

- `assets/content/**` runtime art referenced by `docs/activity-database-data.js`, `docs/activity-database.json`, scripts, tests, export tooling, or generated data.
- `assets/loading/**` while boot/loading animation work is dirty and untracked in the current worktree.
- `assets/android/**` because export presets reference launcher icon paths directly.
- `project.godot` boot splash path `res://assets/loading/idle-elite-player-hub-launch-loading-screen.png`.
- `.import` files because Godot stores source/remap metadata in them; move/rename only with the paired asset and validate.
- `.gd.uid` files because Godot generated script UIDs may be expected by the editor/project cache.
- Public/export/store assets and build/release outputs unless the export scripts and presets are updated together.
- `docs/activity-database-data.js` because it is generated from the activity database; prefer editing the source database and sync script outputs when necessary.

## Generated, Import, Cache, And Output Files

- `.import` files are generated metadata but should remain tracked beside tracked runtime assets when the matching source asset is tracked.
- Untracked `.import` files for new dirty assets should not be committed unless their paired asset is intentionally accepted.
- `output/` and `test-results/` are generated local outputs and should be cleaned or ignored rather than reorganized as project source.
- `.codex-tmp/`, `.codex-tools/`, `.godot/`, `builds/`, `release/`, and `play-store/` are not part of the naming cleanup surface unless a specific stale artifact is proven safe to remove.
- `docs/art-source/asset-sources/fishing-module-preview-sources/*-v1` through `*-v8-*` files are candidate-generation history. They are likely cleanup targets, but only after identifying approved/runtime descendants and preserving any docs that explain final selections.

## Duplicate Or Unused Cleanup Suspects

- Blue Guy loading variants in `assets/loading` include names like `before-frame2-smaller-right`, `before-frame4-up5`, `before-frame4-up8`, and `source`. These are dirty/untracked and should be resolved as one loading-asset cleanup once the current boot-loading work is intentionally accepted or discarded.
- `docs/art-source/asset-sources/fishing-module-preview-sources` has many repeated version ladders per fishing area. These should be reduced to approved source/archival names once final descendants and explanatory docs are preserved.
- `docs/art-source/asset-sources/...` includes `.import` files whose `source_file` entries often point at `res://assets/...` rather than the docs path. Treat those as suspicious generated metadata; do not rely on them until checked in Godot.
- Runtime and art-source folders both contain generic `assets/content/ui` and `assets/ui` paths. This is a strong candidate for parent-qualified source-folder naming.
- Exact duplicate detection still needs content-hash verification before deletion. Same-size grouping alone is not proof.

## First Safe High-Value Targets

1. Done: rename the source/archive mirror root from `docs/art-source/assets` to `docs/art-source/asset-sources`, then update docs references. This attacks the repeated `assets/content` confusion without touching runtime `res://assets` paths.
2. Clean or ignore generated local folders `output/` and `test-results/` after confirming they are untracked outputs and not needed artifacts.
3. Resolve the dirty Blue Guy loading asset cluster by choosing the intended runtime files, removing rejected variants, and updating `scripts/ui/boot_flex_loading_animation.gd`, `scripts/main.gd`, `project.godot`, and tests together if the paths change.
4. Done: parent-qualify the fishing module source-generation folder as `docs/art-source/asset-sources/fishing-module-preview-sources`.
5. Audit `assets/ui`, `assets/content/ui`, and `assets/content/ui/navigation-controls` for overlapping UI asset responsibilities. Rename only after reference checks prove the assets are runtime-safe and update all `res://assets/...` references in code/tests/docs.

## Reference Evidence Collected

- Directory grouping found repeated leaf names: `actions` 12, `backgrounds` 11, `ui` 5, several domain folders 2-3 times.
- `rg` found many direct `res://assets` and `assets/content` references in `scripts/main.gd`, `scripts/ui/boot_flex_loading_animation.gd`, tests, export presets, generated docs data, and store-asset tooling.
- `export_presets.cfg` directly references Android launcher icon paths and excludes several source/preview asset patterns from builds.
- `project.godot` still references the older loading splash path.
- Existing dirty/untracked files include navigation-control imports, Blue Guy loading files/imports, UI script UIDs, `output/`, and `test-results/`; these should remain unstaged unless a cleanup step explicitly owns them.

## Working Rules For Future Commits

- Before renaming or deleting an asset, run `rg` for the exact path, basename, and any `res://` form.
- Move assets and their `.import` files together, then validate with focused reference checks and `.\scripts\check-project.ps1`.
- Prefer one folder family or one asset cluster per commit.
- Do not change image/audio content while doing name-only cleanup.
- Do not delete source-generation candidates until an approved/runtime replacement and all references are known.
- If a repeated folder name remains, document why the parent context makes it readable or rename it with a parent-qualified convention.
