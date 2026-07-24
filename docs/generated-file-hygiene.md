# Generated File Hygiene

Use this page before staging generated files, Godot metadata, local outputs, or build artifacts. The goal is to keep commits focused on source changes and the metadata that is required to make those source changes load in Godot.

## Tracked Source And Metadata

- `docs/activity-database.json` is the tracked source for activity data. The Godot runtime and HTTP-served activity docs read it directly; run `.\scripts\check-activity-database-contracts.ps1` and `.\scripts\audit-activity-database.ps1` after JSON or loader changes.
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
- Keep the source/provenance archive outside the project at the sibling `../Idle Slop 1-art-source-archive/`; do not recreate `docs/art-source/` or commit archive files into the runtime repository.
- If Godot creates an untracked `.import` file for a dirty asset, leave it unstaged until the paired asset is intentionally accepted.
- Do not add a broad `*.import` ignore rule. Runtime assets need their import metadata.

## UID Rules

- Do not add a broad `*.uid` ignore rule. Existing tracked `.uid` files can be meaningful Godot or addon metadata.
- Untracked `scripts/ui/*.gd.uid` files should stay out of ordinary readability commits unless that package explicitly accepts script UID metadata, explains the ownership reason, and validates the affected script paths.
- Do not rename or delete `.gd.uid` files as cosmetic cleanup. Treat them as Godot metadata tied to script identity.

## Never Hand Edit

- `.godot/`, `.firebase/`, and Android build cache contents.
- Local secrets or signing material.
- Export outputs in `builds/`, `release/`, `export/`, or Android build output folders unless the work package is a release/build package.

## Validation

- Run `.\scripts\check-generated-file-hygiene.ps1` after changing `.gitignore`, generated-file docs, build-output docs, or metadata rules.
- Run `.\scripts\check-runtime-asset-paths.ps1` after moving runtime assets or import metadata.
- Run `.\scripts\check-project.ps1` when practical, then verify no headless Godot process was left behind.
