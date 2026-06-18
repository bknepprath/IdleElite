# Generated File Hygiene

Use this page before staging generated files, Godot metadata, local outputs, or build artifacts. The goal is to keep commits focused on source changes and the metadata that is required to make those source changes load in Godot.

## Tracked Source And Metadata

- `docs/activity-database.json` is source. `docs/activity-database-data.js` is generated from it but tracked because the game loads it at runtime and Android export includes it. Regenerate it with `python scripts\sync-activity-database-js.py` after JSON edits, then run `.\scripts\audit-activity-database.ps1` and `.\scripts\check-activity-database-contracts.ps1`.
- Runtime `.png.import` files are tracked when the matching runtime image is tracked. Move or delete the asset and its `.import` file together, and search for the exact path plus the `res://` path first.
- Existing tracked addon or vendor `.uid` and `.import` files are part of that imported package. Do not delete them as generic cleanup.
- Some Godot-generated files can be intentionally tracked when they are the durable metadata for committed runtime assets. The package that accepts them should also validate the matching runtime path.

## Ignored Or Local Outputs

These are local machine, build, cache, or validation outputs. Do not stage them unless a package explicitly changes the build contract and explains why.

- `.godot/`
- `.firebase/`
- `.codex-tools/`
- `.codex-tmp/`
- `export/`
- `builds/`
- `release/`
- `output/`
- `test-results/`
- `android/build/.gradle/`
- `android/build/build/`
- `android/build/assetPack*/`
- `android/build/libs/debug/`
- `android/build/libs/release/`
- local key and certificate files such as `*.keystore`, `*.jks`, `*.p12`, and `*.pem`
- `firebase-leaderboard-config.json`
- local release notes and preview scratch files such as `local-release-notes.md` and `docs/loading-flex-preview.html`

## Import Metadata Rules

- Commit `.import` files beside accepted runtime assets, especially under `assets/content/**`, `assets/loading/**`, and `assets/android/**`.
- Do not commit docs-side `.import` files under `docs/art-source/**`. That tree is a source/provenance archive under `.gdignore`, and the old Godot metadata there was removed as stale archive noise.
- If Godot creates an untracked `.import` file for a dirty asset, leave it unstaged until the paired asset is intentionally accepted.
- Do not add a broad `*.import` ignore rule. Runtime assets need their import metadata.

## UID Rules

- Do not add a broad `*.uid` ignore rule. Existing tracked `.uid` files can be meaningful Godot or addon metadata.
- Untracked `scripts/ui/*.gd.uid` files should stay out of ordinary readability commits unless that package explicitly accepts script UID metadata, explains the ownership reason, and validates the affected script paths.
- Do not rename or delete `.gd.uid` files as cosmetic cleanup. Treat them as Godot metadata tied to script identity.

## Never Hand Edit

- `.godot/`, `.firebase/`, and Android build cache contents.
- `docs/activity-database-data.js` except through `scripts\sync-activity-database-js.py`.
- Local secrets or signing material.
- Export outputs in `builds/`, `release/`, `export/`, or Android build output folders unless the work package is a release/build package.

## Validation

- Run `.\scripts\check-generated-file-hygiene.ps1` after changing `.gitignore`, generated-file docs, build-output docs, or metadata rules.
- Run `.\scripts\check-runtime-asset-paths.ps1` after moving runtime assets or import metadata.
- Run `.\scripts\check-project.ps1` when practical, then verify no headless Godot process was left behind.
